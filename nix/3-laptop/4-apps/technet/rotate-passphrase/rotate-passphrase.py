"""Rotate Passphrase

Replaces a host's disk passphrase with one typed at a hidden prompt, or a backup set's borg passphrase with a random one, on the machines and in sops.
Run it on Odin, as beatlink, from the root of a TechNet checkout. A passphrase only reaches a tool on stdin or in a root-only file under /run,
every command is a fixed argument list, and no tool's output is ever printed.
"""

import getpass
import hashlib
import json
import secrets
import shlex
import subprocess
import sys
from pathlib import Path

# Plumbing ###########################################################################################################################################

LOCAL_HOST = "odin"
ROOT_PATH = "PATH=/run/wrappers/bin:/run/current-system/sw/bin"
DIAGNOSTIC_PREFIXES = ("Platform:", "Linux:", "Borg:", "Python:", "PID:", "CWD:", "sys.argv:", "SSH_ORIGINAL_COMMAND:")
SECRETS = set()


class RotateError(Exception):
    """A step failed; its message never holds a secret."""


def redact(text):
    """Masks any secret this run has seen, as a last guard on anything printed."""
    for secret in SECRETS:
        text = text.replace(secret, "<redacted>")
    return text


def say(message):
    """Prints a progress line."""
    print(redact(f"rotate-passphrase: {message}"), flush=True)


def secret(value):
    """Registers a value as secret so it can never be printed, and returns it."""
    if value:
        SECRETS.add(value)
    return value


def digest(value):
    """A hash of a value, for comparing two secrets without showing either."""
    return hashlib.sha256(value.encode()).hexdigest()


def run(argv, data=None, host=LOCAL_HOST, root=False):
    """Runs a command here or on a host with data on stdin, and returns its output without printing it."""
    if root:
        argv = ["sudo", "-n", "env", ROOT_PATH, *argv]
    if host != LOCAL_HOST:
        argv = ["ssh", "-o", "BatchMode=yes", host, shlex.join(argv)]
    result = subprocess.run(argv, input=data, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        lines = [line for line in result.stderr.strip().splitlines() if line.strip() and not line.startswith(DIAGNOSTIC_PREFIXES)]
        reason = (lines or ["no error output"])[-1]
        raise RotateError(f"{host}: {argv[-1] if host != LOCAL_HOST else shlex.join(argv)} failed: {reason}")
    return result.stdout


# Sops ###############################################################################################################################################


def sops_value(file, key):
    """Decrypts one value from a sops file into memory."""
    return secret(run(["sops", "--decrypt", "--extract", f'["{key}"]', file]))


def sops_store(file, key, value):
    """Stores a value in a sops file, then reads it back and compares hashes."""
    run(["sops", "set", "--value-stdin", file, f'["{key}"]'], data=json.dumps(value))
    if digest(sops_value(file, key)) != digest(value):
        raise RotateError(f"{file} {key} did not read back as written")
    say(f"stored {key} in {file}")


# Staging ############################################################################################################################################


def stage(host, owner, **values):
    """Writes each value to its own file in a fresh directory under /run on a host, readable only by owner, and returns the directory."""
    directory = run(["mktemp", "-d", "-p", "/run", "rotate-passphrase.XXXXXX"], host=host, root=True).strip()
    run(["chown", owner, directory], host=host, root=True)
    for name, value in values.items():
        run(["install", "-m", "0400", "-o", owner, "/dev/stdin", f"{directory}/{name}"], data=value, host=host, root=True)
    return directory


def unstage(host, directory):
    """Removes a staging directory."""
    run(["rm", "-rf", "--", directory], host=host, root=True)


# ZFS ################################################################################################################################################


def zfs_rotate(host, roots, new):
    """Moves each encryption root to the new passphrase, then checks it opens with it."""
    for root in roots:
        run(["zfs", "change-key", "-o", "keyformat=passphrase", "-o", "keylocation=prompt", root], data=new, host=host, root=True)
        try:
            run(["zfs", "load-key", "-n", "-L", "prompt", root], data=new, host=host, root=True)
        except RotateError as error:
            raise RotateError(f"{host} {root} does not open with the new passphrase") from error
        say(f"{host}: {root} now uses the new passphrase")


# LUKS ###############################################################################################################################################


def luks_device(host, name):
    """The block device behind an open LUKS mapping."""
    for line in run(["cryptsetup", "status", name], host=host, root=True).splitlines():
        field, _, value = line.strip().partition(":")
        if field == "device":
            return value.strip()
    raise RotateError(f"{host}: {name} is not open")


def luks_rotate(host, names, old, new):
    """Replaces the old passphrase's keyslot on each LUKS device, then checks the new one opens it; clevis slots hold keys of their own."""
    for name in names:
        device = luks_device(host, name)
        directory = stage(host, "root", old=old, new=new)
        try:
            run(["cryptsetup", "luksChangeKey", "--key-file", f"{directory}/old", device, f"{directory}/new"], host=host, root=True)
            run(["cryptsetup", "open", "--test-passphrase", "--key-file", f"{directory}/new", device], host=host, root=True)
        finally:
            unstage(host, directory)
        say(f"{host}: {name} now uses the new passphrase")


# Borg ###############################################################################################################################################

CHANGE = 'BORG_PASSPHRASE=$(cat "$1") BORG_NEW_PASSPHRASE=$(cat "$2") exec borg key change-passphrase --lock-wait 600 "$3"'
LIST = 'BORG_PASSPHRASE=$(cat "$1") exec borg list --lock-wait 600 --last 1 --format "{archive}{NL}" "$2"'


def borg_change(host, owner, path, old, new):
    """Changes one repository from the old passphrase to the new, as the user that owns it, then lists it with the new one."""
    group = run(["id", "-g", owner], host=host).strip()
    directory = stage(host, owner, old=old, new=new)
    try:
        run(["install", "-d", "-m", "0700", "-o", owner, f"{directory}/base"], host=host, root=True)
        as_owner = ["setpriv", f"--reuid={owner}", f"--regid={group}", "--init-groups", "env", f"BORG_BASE_DIR={directory}/base",
                    "BORG_RELOCATED_REPO_ACCESS_IS_OK=yes", "BORG_DISPLAY_PASSPHRASE=no"]
        run([*as_owner, "sh", "-c", CHANGE, "sh", f"{directory}/old", f"{directory}/new", path], host=host, root=True)
        run([*as_owner, "sh", "-c", LIST, "sh", f"{directory}/new", path], host=host, root=True)
    finally:
        unstage(host, directory)


def borg_rotate(repositories, old, new):
    """Changes every repository in a set, and puts back the ones already done if one fails."""
    done = []
    for host, owner, path in repositories:
        try:
            borg_change(host, owner, path, old, new)
        except RotateError as error:
            say(f"{host}: {path} could not be changed: {error}")
            for done_host, done_owner, done_path in done:
                borg_change(done_host, done_owner, done_path, new, old)
                say(f"{done_host}: {done_path} put back to the old passphrase")
            raise RotateError("the set was left on its old passphrase") from error
        done.append((host, owner, path))
        say(f"{host}: {path} now uses the new passphrase")


# Keyring ############################################################################################################################################


def keyring_store(urls, new):
    """Points Vorta's keyring entry for each repository URL at the new passphrase, then reads it back."""
    for url in urls:
        attributes = ["application", "Vorta", "service", "vorta-repo", "repo_url", url]
        run(["secret-tool", "store", "--label", f"Vorta Backup Repo {url}", *attributes, "xdg:schema", "org.freedesktop.Secret.Generic"], data=new)
        if digest(secret(run(["secret-tool", "lookup", *attributes]))) != digest(new):
            raise RotateError(f"the keyring entry for {url} did not read back as written")
        say(f"keyring entry for {url} updated")


# Targets ############################################################################################################################################

HEIMDALL = "heimdall.technet"
RAGNAROK = "ragnarok.technet"
THOR = "thor.technet"


def random_passphrase():
    """A new random borg passphrase, held only in memory and in sops."""
    return secret(secrets.token_urlsafe(48))


def prompt_new(what):
    """Asks twice for the new passphrase at a hidden prompt."""
    new = secret(getpass.getpass(f"New passphrase for {what}: "))
    if new != getpass.getpass("Repeat it: "):
        raise RotateError("the two entries differ")
    if not new or "\n" in new:
        raise RotateError("the passphrase is empty or contains a newline")
    return new


def rotate_heimdall():
    """Heimdall's ZFS root and data pools."""
    new = prompt_new("Heimdall's disks")
    zfs_rotate(HEIMDALL, ["root-pool-Heimdall/root", "data-pool-Heimdall/storage"], new)
    sops_store("secrets/2-server/clevis.yaml", "zfs_passphrase", new)
    return ["secrets/2-server/clevis.yaml"], (
        "Land this commit and switch Heimdall. Then start tang on Odin, run 'sudo rebind-clevis' on Heimdall, "
        "and switch Heimdall again so its initrd carries the new bindings."
    )


def rotate_ragnarok():
    """Ragnarok's LUKS root and backup drives."""
    old = sops_value("secrets/1-backup-server/clevis.yaml", "zfs_passphrase")
    new = prompt_new("Ragnarok's disks")
    luks_rotate(RAGNAROK, ["cryptroot", "cryptstorage"], old, new)
    sops_store("secrets/1-backup-server/clevis.yaml", "zfs_passphrase", new)
    return ["secrets/1-backup-server/clevis.yaml"], "Land this commit and switch Ragnarok."


def rotate_thor():
    """Thor's LUKS root and SD card."""
    old = sops_value("secrets/5-phone/clevis.yaml", "zfs_passphrase")
    new = prompt_new("Thor's disks")
    luks_rotate(THOR, ["cryptroot", "cryptstorage"], old, new)
    sops_store("secrets/5-phone/clevis.yaml", "zfs_passphrase", new)
    sops_store("secrets/admin/nixtool.yaml", "thor_encryption_key", new)
    return ["secrets/5-phone/clevis.yaml", "secrets/admin/nixtool.yaml"], "Land this commit and switch Thor."


def rotate_odin():
    """Odin's ZFS root and data pools, typed at every boot."""
    new = prompt_new("Odin's disks")
    zfs_rotate(LOCAL_HOST, ["root-pool-Odin/root", "data-pool-Odin"], new)
    sops_store("secrets/admin/nixtool.yaml", "odin_encryption_key", new)
    return ["secrets/admin/nixtool.yaml"], "Land this commit. Odin asks for the new passphrase at its next boot."


def rotate_server_backups():
    """Heimdall's borgmatic repositories, also opened by Ragnarok's checks."""
    old = sops_value("secrets/2-server/borgmatic.yaml", "borg_repo_encryption_key")
    new = random_passphrase()
    borg_rotate([(HEIMDALL, "root", "/Storage/Files/Backups/Server/Borgmatic"), (RAGNAROK, "borg", "/Storage/Backups/Server/Borgmatic")], old, new)
    sops_store("secrets/2-server/borgmatic.yaml", "borg_repo_encryption_key", new)
    sops_store("secrets/1-backup-server/borg-check.yaml", "borg_repo_encryption_key", new)
    return (["secrets/2-server/borgmatic.yaml", "secrets/1-backup-server/borg-check.yaml"],
            "Land this commit and switch Heimdall and Ragnarok; their backups and checks fail until then.")


def rotate_laptop_backups():
    """Odin's borgmatic repositories."""
    old = sops_value("secrets/3-laptop/borgmatic.yaml", "borg_repo_encryption_key")
    new = random_passphrase()
    borg_rotate([(LOCAL_HOST, "root", "/Storage/Files/Backups/Laptop/Borgmatic"), (HEIMDALL, "borg", "/Storage/Files/Backups/Laptop/Borgmatic"),
                 (RAGNAROK, "borg", "/Storage/Backups/Laptop/Borgmatic")], old, new)
    sops_store("secrets/3-laptop/borgmatic.yaml", "borg_repo_encryption_key", new)
    return ["secrets/3-laptop/borgmatic.yaml"], "Land this commit and switch Odin; its borgmatic backups fail until then."


def rotate_vorta_backups():
    """Odin's Vorta repositories and their keyring entries."""
    old = sops_value("secrets/3-laptop/vorta.yaml", "vorta_backup_passphrase")
    new = random_passphrase()
    borg_rotate([(LOCAL_HOST, "beatlink", "/Storage/Files/Backups/Laptop/Vorta"), (HEIMDALL, "borg", "/Storage/Files/Backups/Laptop/Vorta"),
                 (RAGNAROK, "borg", "/Storage/Backups/Laptop/Vorta")], old, new)
    keyring_store(["ssh://borg@heimdall.technet/Storage/Files/Backups/Laptop/Vorta", "ssh://borg@ragnarok.technet/Storage/Backups/Laptop/Vorta",
                   "/Storage/Files/Backups/Laptop/Vorta"], new)
    sops_store("secrets/3-laptop/vorta.yaml", "vorta_backup_passphrase", new)
    return ["secrets/3-laptop/vorta.yaml"], "Land this commit and switch Odin, so Vigil's Vorta checks use the new passphrase."


TARGETS = {
    "heimdall": rotate_heimdall,
    "ragnarok": rotate_ragnarok,
    "thor": rotate_thor,
    "odin": rotate_odin,
    "server-backups": rotate_server_backups,
    "laptop-backups": rotate_laptop_backups,
    "vorta-backups": rotate_vorta_backups,
}

# Main ###############################################################################################################################################


def main(arguments):
    """Checks it runs from a clean TechNet checkout, rotates one target and commits the changed sops files."""
    if len(arguments) != 1 or arguments[0] not in TARGETS:
        print("Usage: rotate-passphrase <" + "|".join(TARGETS) + ">", file=sys.stderr)
        return 2
    target = arguments[0]
    try:
        if not (Path(".sops.yaml").is_file() and Path("secrets").is_dir()):
            raise RotateError("run this from the root of a TechNet checkout")
        if run(["git", "status", "--porcelain", "--", "secrets"]).strip():
            raise RotateError("secrets/ has uncommitted changes; commit or discard them first")
        files, after = TARGETS[target]()
        run(["git", "add", "--", *files])
        run(["git", "commit", "-q", "-m", f"chore(secrets): rotate the {target} passphrase", "--", *files])
        say(f"committed. {after}")
        return 0
    except RotateError as error:
        say(f"stopped: {error}")
    except KeyboardInterrupt:
        say("stopped by Ctrl+C")
    except Exception as error:  # Never let a traceback carry a value to the terminal
        say(f"stopped by an unexpected {type(error).__name__}")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
