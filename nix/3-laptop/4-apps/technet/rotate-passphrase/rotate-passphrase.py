"""Rotate Passphrase

Replaces disk passphrases and login passwords typed at a hidden prompt, and backup passphrases with random ones; then commits, pushes and deploys.
Run it on Odin, as beatlink, from the root of the TechNet main checkout. A secret only reaches a tool on stdin or in a root-only file under /run,
every command is a fixed argument list, and anything printed passes through a filter that masks every secret this run has seen.
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
    for value in SECRETS:
        text = text.replace(value, "<redacted>")
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


def wrap(argv, host, root):
    """The argument list that runs a command here or on a host, as root when asked."""
    if root:
        argv = ["sudo", "-n", "env", ROOT_PATH, *argv]
    if host != LOCAL_HOST:
        argv = ["ssh", "-o", "BatchMode=yes", "-o", "ServerAliveInterval=30", host, shlex.join(argv)]
    return argv


def run(argv, data=None, host=LOCAL_HOST, root=False):
    """Runs a command with data on stdin and returns its output without printing it."""
    full = wrap(argv, host, root)
    result = subprocess.run(full, input=data, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        lines = [line for line in result.stderr.strip().splitlines() if line.strip() and not line.startswith(DIAGNOSTIC_PREFIXES)]
        raise RotateError(f"{host}: {shlex.join(argv)} failed: {(lines or ['no error output'])[-1]}")
    return result.stdout


def run_shown(argv, host=LOCAL_HOST, root=False):
    """Runs a long command that takes no secret, showing its output line by line through the mask."""
    with subprocess.Popen(wrap(argv, host, root), stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True) as process:
        for line in process.stdout:
            print(redact(line), end="", flush=True)
    if process.returncode != 0:
        raise RotateError(f"{host}: {shlex.join(argv)} failed")


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


def zfs_change(host, root, value):
    """Moves one encryption root to a passphrase, then checks it opens with it."""
    run(["zfs", "change-key", "-o", "keyformat=passphrase", "-o", "keylocation=prompt", root], data=value, host=host, root=True)
    run(["zfs", "load-key", "-n", "-L", "prompt", root], data=value, host=host, root=True)


def zfs_rotate(host, roots, old, new):
    """Moves each encryption root to the new passphrase, and puts back the ones already done if one fails."""
    done = []
    for root in roots:
        try:
            zfs_change(host, root, new)
        except RotateError as error:
            for done_root in done:
                zfs_change(host, done_root, old)
                say(f"{host}: {done_root} put back to the old passphrase")
            raise RotateError(f"{host} {root} could not be changed, so the host was left on its old passphrase") from error
        done.append(root)
        say(f"{host}: {root} now uses the new passphrase")


# LUKS ###############################################################################################################################################


def luks_device(host, name):
    """The block device behind an open LUKS mapping."""
    for line in run(["cryptsetup", "status", name], host=host, root=True).splitlines():
        field, _, value = line.strip().partition(":")
        if field == "device":
            return value.strip()
    raise RotateError(f"{host}: {name} is not open")


def luks_change(host, device, old, new):
    """Replaces the old passphrase's keyslot on one LUKS device, then checks the new one opens it."""
    directory = stage(host, "root", old=old, new=new)
    try:
        run(["cryptsetup", "luksChangeKey", "--key-file", f"{directory}/old", device, f"{directory}/new"], host=host, root=True)
        run(["cryptsetup", "open", "--test-passphrase", "--key-file", f"{directory}/new", device], host=host, root=True)
    finally:
        unstage(host, directory)


def luks_rotate(host, names, old, new):
    """Changes each LUKS device, and puts back the ones already done if one fails; clevis slots hold keys of their own and stay as they are."""
    devices = [(name, luks_device(host, name)) for name in names]
    done = []
    for name, device in devices:
        try:
            luks_change(host, device, old, new)
        except RotateError as error:
            for done_name, done_device in done:
                luks_change(host, done_device, new, old)
                say(f"{host}: {done_name} put back to the old passphrase")
            raise RotateError(f"{host} {name} could not be changed, so the host was left on its old passphrase") from error
        done.append((name, device))
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
        as_owner = [
            "setpriv",
            f"--reuid={owner}",
            f"--regid={group}",
            "--init-groups",
            "env",
            f"BORG_BASE_DIR={directory}/base",
            "BORG_RELOCATED_REPO_ACCESS_IS_OK=yes",
            "BORG_DISPLAY_PASSPHRASE=no",
        ]
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


def keyring_store(urls, new):
    """Points Vorta's keyring entry for each repository URL at the new passphrase, then reads it back."""
    for url in urls:
        attributes = ["application", "Vorta", "service", "vorta-repo", "repo_url", url]
        run(["secret-tool", "store", "--label", f"Vorta Backup Repo {url}", *attributes, "xdg:schema", "org.freedesktop.Secret.Generic"], data=new)
        if digest(secret(run(["secret-tool", "lookup", *attributes]))) != digest(new):
            raise RotateError(f"the keyring entry for {url} did not read back as written")
        say(f"keyring entry for {url} updated")


# Pausing Backups ####################################################################################################################################

HEIMDALL = "heimdall.technet"
RAGNAROK = "ragnarok.technet"
THOR = "thor.technet"

BORG_UNITS = {
    HEIMDALL: ["borgmatic", "borgmatic-check", "borg-compact-laptop-vorta"],
    RAGNAROK: ["borg-check", "borg-check-data", "borg-compact-laptop-vorta"],
    LOCAL_HOST: ["borgmatic", "borgmatic-check", "borgmatic-check-data", "borg-compact-vorta"],
}
VORTA_UNITS = ["vorta-backup-1-on-disk-backup", "vorta-backup-2-heimdall-backup", "vorta-backup-3-ragnarok-backup"]


def pause_backups():
    """Stops every borg timer and job on the three backup hosts, and Vorta, so nothing holds a repository while it changes."""
    for host, units in BORG_UNITS.items():
        run(["systemctl", "stop", *[f"{unit}.timer" for unit in units], *[f"{unit}.service" for unit in units]], host=host, root=True)
        say(f"{host}: backups paused")
    run(["systemctl", "--user", "stop", *[f"{unit}.timer" for unit in VORTA_UNITS], *[f"{unit}.service" for unit in VORTA_UNITS], "vorta.service"])
    say("odin: Vorta paused")


def resume_backups():
    """Starts the borg timers and Vorta again, reporting rather than stopping on a host that fails."""
    for host, units in BORG_UNITS.items():
        try:
            run(["systemctl", "start", *[f"{unit}.timer" for unit in units]], host=host, root=True)
            say(f"{host}: backups resumed")
        except RotateError as error:
            say(f"could not resume backups: {error}")
    try:
        run(["systemctl", "--user", "start", *[f"{unit}.timer" for unit in VORTA_UNITS], "vorta.service"])
        say("odin: Vorta resumed")
    except RotateError as error:
        say(f"could not resume Vorta: {error}")


# Deploying ##########################################################################################################################################

DEPLOY_ORDER = ["Heimdall", "Ragnarok", "Thor", "Odin"]
ADDRESSES = {"Heimdall": HEIMDALL, "Ragnarok": RAGNAROK, "Thor": THOR, "Odin": "odin.technet"}
POST_SWITCH = {"Thor": ["sh", "-c", "systemctl is-active -q phosh.service || systemctl restart phosh.service"]}


def deploy(name):
    """Switches one host to the checkout the way Vigil does: sleep held off for the switch, and its after-switch step run."""
    address = ADDRESSES[name]
    say(f"switching {name}")
    inhibit = subprocess.Popen(
        wrap(["systemd-inhibit", "--what=idle:sleep", "--mode=block", "--why=rotate-passphrase is deploying", "cat"], address, True),
        stdin=subprocess.PIPE,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        run_shown(
            [
                "nixos-rebuild",
                "switch",
                "--flake",
                f"{Path.cwd()}#{name}",
                "--target-host",
                f"beatlink@{address}",
                "--sudo",
                "--use-substitutes",
                "--no-reexec",
                "--no-write-lock-file",
            ]
        )
    finally:
        inhibit.stdin.close()
        inhibit.wait()
    if name in POST_SWITCH:
        run(POST_SWITCH[name], host=address, root=True)
    say(f"{name} switched")


def rebind_heimdall():
    """Renews Heimdall's clevis bindings with tang running, then switches it again so its initrd carries them."""
    tang_was_running = subprocess.run(["systemctl", "is-active", "-q", "tangd.socket"], check=False).returncode == 0
    if not tang_was_running:
        run(["systemctl", "start", "tangd.socket"], root=True)
    try:
        run_shown(["rebind-clevis"], host=HEIMDALL, root=True)
    finally:
        if not tang_was_running:
            run(["systemctl", "stop", "tangd.socket"], root=True)
    deploy("Heimdall")


def land():
    """Pushes the new commits, rebasing onto anything that landed meanwhile; only secrets/ changed here, so a rebase cannot disturb other work."""
    try:
        run(["git", "push", "-q", "origin", "HEAD:main"])
    except RotateError:
        run(["git", "pull", "-q", "--rebase", "origin", "main"])
        run(["git", "push", "-q", "origin", "HEAD:main"])
    say("pushed")


# Targets ############################################################################################################################################


def prompt_new(what):
    """Asks twice for a new passphrase at a hidden prompt."""
    new = secret(getpass.getpass(f"New passphrase for {what}: "))
    if new != getpass.getpass("Repeat it: "):
        raise RotateError("the two entries differ")
    if not new or "\n" in new:
        raise RotateError("the passphrase is empty or contains a newline")
    return new


def hashed_password(what):
    """Asks for a new login password and keeps only its yescrypt hash."""
    return secret(run(["mkpasswd", "--method=yescrypt", "--stdin"], data=prompt_new(what)).strip())


def random_passphrase():
    """A new random borg passphrase, held only in memory and in sops."""
    return secret(secrets.token_urlsafe(48))


def apply_heimdall(new):
    """Heimdall's ZFS root and data pools."""
    zfs_rotate(HEIMDALL, ["root-pool-Heimdall/root", "data-pool-Heimdall/storage"], sops_value("secrets/2-server/clevis.yaml", "zfs_passphrase"), new)


def apply_ragnarok(new):
    """Ragnarok's LUKS root and backup drives."""
    luks_rotate(RAGNAROK, ["cryptroot", "cryptstorage"], sops_value("secrets/1-backup-server/clevis.yaml", "zfs_passphrase"), new)


def apply_thor(new):
    """Thor's LUKS root and SD card."""
    luks_rotate(THOR, ["cryptroot", "cryptstorage"], sops_value("secrets/5-phone/clevis.yaml", "zfs_passphrase"), new)


def apply_odin(new):
    """Odin's ZFS root and data pools, typed at every boot."""
    zfs_rotate(LOCAL_HOST, ["root-pool-Odin/root", "data-pool-Odin"], sops_value("secrets/admin/nixtool.yaml", "odin_encryption_key"), new)


def apply_server_backups(new):
    """Heimdall's borgmatic repositories, also opened by Ragnarok's checks."""
    borg_rotate(
        [(HEIMDALL, "root", "/Storage/Files/Backups/Server/Borgmatic"), (RAGNAROK, "borg", "/Storage/Backups/Server/Borgmatic")],
        sops_value("secrets/2-server/borgmatic.yaml", "borg_repo_encryption_key"),
        new,
    )


def apply_laptop_backups(new):
    """Odin's borgmatic repositories."""
    borg_rotate(
        [
            (LOCAL_HOST, "root", "/Storage/Files/Backups/Laptop/Borgmatic"),
            (HEIMDALL, "borg", "/Storage/Files/Backups/Laptop/Borgmatic"),
            (RAGNAROK, "borg", "/Storage/Backups/Laptop/Borgmatic"),
        ],
        sops_value("secrets/3-laptop/borgmatic.yaml", "borg_repo_encryption_key"),
        new,
    )


def apply_vorta_backups(new):
    """Odin's Vorta repositories and their keyring entries."""
    borg_rotate(
        [
            (LOCAL_HOST, "beatlink", "/Storage/Files/Backups/Laptop/Vorta"),
            (HEIMDALL, "borg", "/Storage/Files/Backups/Laptop/Vorta"),
            (RAGNAROK, "borg", "/Storage/Backups/Laptop/Vorta"),
        ],
        sops_value("secrets/3-laptop/vorta.yaml", "vorta_backup_passphrase"),
        new,
    )
    keyring_store(
        [
            "ssh://borg@heimdall.technet/Storage/Files/Backups/Laptop/Vorta",
            "ssh://borg@ragnarok.technet/Storage/Backups/Laptop/Vorta",
            "/Storage/Files/Backups/Laptop/Vorta",
        ],
        new,
    )


def apply_nothing(new):
    """For targets whose only copy is in sops."""


# KeePassXC ##########################################################################################################################################

KEEPASSXC_DATABASE = "/Storage/Files/Documents/SecurityDatabase.kdbx"
KEEPASSXC_BUS = ["busctl", "--user", "--timeout=60", "call", "org.keepassxc.KeePassXC.MainWindow", "/keepassxc"]


def keepassxc_opens(password):
    """Whether the database opens with a password."""
    try:
        run(["keepassxc-cli", "db-info", "-q", KEEPASSXC_DATABASE], data=f"{password}\n")
        return True
    except RotateError:
        return False


def keepassxc_passwords():
    """Asks for the current master password, checks it opens the database, then asks twice for the new one."""
    current = secret(getpass.getpass("Current KeePassXC master password: "))
    if not keepassxc_opens(current):
        raise RotateError("that is not the current KeePassXC master password")
    return current, prompt_new("your KeePassXC database")


def keepassxc_app_running():
    """Whether the KeePassXC app is running in this session."""
    try:
        run([*KEEPASSXC_BUS, "org.freedesktop.DBus.Peer", "Ping"])
        return True
    except RotateError:
        return False


def apply_keepassxc(passwords):
    """Closes the database in the app, changes its master password, checks it, and asks the app to open it again."""
    current, new = passwords
    running = keepassxc_app_running()
    if running:
        run([*KEEPASSXC_BUS, "org.keepassxc.KeePassXC.MainWindow", "closeAllDatabases"])
        if "/org/freedesktop/secrets/collection/" in run(["busctl", "--user", "tree", "org.keepassxc.KeePassXC.MainWindow"]):
            raise RotateError("KeePassXC still has the database open; save or discard its changes, close it, and run this target again")
    run(["keepassxc-cli", "db-edit", "-q", "--set-password", KEEPASSXC_DATABASE], data=f"{current}\n{new}\n{new}\n")
    if not keepassxc_opens(new) or keepassxc_opens(current):
        raise RotateError("the database did not take the new master password")
    say("KeePassXC master password changed")
    if running:
        run([*KEEPASSXC_BUS, "org.keepassxc.KeePassXC.MainWindow", "openDatabase", "s", KEEPASSXC_DATABASE])
        say("KeePassXC is asking for the new master password")


# Each target: how its new value is made, what changes on the machines, where sops keeps it, and which hosts switch to it.
TARGETS = {
    "server-backups": dict(
        make=random_passphrase,
        apply=apply_server_backups,
        borg=True,
        hosts=["Heimdall", "Ragnarok"],
        store=[
            ("secrets/2-server/borgmatic.yaml", "borg_repo_encryption_key"),
            ("secrets/1-backup-server/borg-check.yaml", "borg_repo_encryption_key"),
        ],
    ),
    "laptop-backups": dict(
        make=random_passphrase,
        apply=apply_laptop_backups,
        borg=True,
        hosts=["Odin"],
        store=[("secrets/3-laptop/borgmatic.yaml", "borg_repo_encryption_key")],
    ),
    "vorta-backups": dict(
        make=random_passphrase,
        apply=apply_vorta_backups,
        borg=True,
        hosts=["Odin"],
        store=[("secrets/3-laptop/vorta.yaml", "vorta_backup_passphrase")],
    ),
    "heimdall": dict(
        make=lambda: prompt_new("Heimdall's disks"),
        apply=apply_heimdall,
        hosts=["Heimdall"],
        store=[("secrets/2-server/clevis.yaml", "zfs_passphrase")],
    ),
    "ragnarok": dict(
        make=lambda: prompt_new("Ragnarok's disks"),
        apply=apply_ragnarok,
        hosts=["Ragnarok"],
        store=[("secrets/1-backup-server/clevis.yaml", "zfs_passphrase")],
    ),
    "thor": dict(
        make=lambda: prompt_new("Thor's disks"),
        apply=apply_thor,
        hosts=["Thor"],
        store=[("secrets/5-phone/clevis.yaml", "zfs_passphrase"), ("secrets/admin/nixtool.yaml", "thor_encryption_key")],
    ),
    "odin": dict(make=lambda: prompt_new("Odin's disks"), apply=apply_odin, hosts=[], store=[("secrets/admin/nixtool.yaml", "odin_encryption_key")]),
    "login": dict(
        make=lambda: hashed_password("your login on every host"),
        apply=apply_nothing,
        hosts=["Heimdall", "Ragnarok", "Thor", "Odin"],
        store=[("secrets/0-common/users.yaml", "beatlink_hashed_password"), ("secrets/5-phone/users.yaml", "beatlink_hashed_password_phone")],
    ),
    "keepassxc": dict(make=keepassxc_passwords, apply=apply_keepassxc, hosts=[], store=[], last=True),
}

# Main ###############################################################################################################################################


def preflight():
    """Checks it runs from an up-to-date, clean TechNet main checkout, fast-forwarding it if it is behind."""
    if not (Path(".sops.yaml").is_file() and Path("secrets").is_dir()):
        raise RotateError("run this from the root of the TechNet checkout")
    if run(["git", "rev-parse", "--abbrev-ref", "HEAD"]).strip() != "main":
        raise RotateError("check out main first")
    if run(["git", "status", "--porcelain", "--", "secrets"]).strip():
        raise RotateError("secrets/ has uncommitted changes; commit or discard them first")
    run(["git", "fetch", "-q", "origin"])
    run(["git", "merge", "-q", "--ff-only", "origin/main"])


def rotate_all(names, values):
    """Rotates each target in turn, committing each; returns the ones that finished, stopping at the first that fails."""
    done = []
    for name in names:
        target, new = TARGETS[name], values[name]
        try:
            say(f"rotating {name}")
            target["apply"](new)
            for file, key in target["store"]:
                sops_store(file, key, new)
            files = [file for file, _ in target["store"]]
            if files:
                run(["git", "add", "--", *files])
                run(["git", "commit", "-q", "-m", f"chore(secrets): rotate the {name} passphrase", "--", *files])
            done.append(name)
        except RotateError as error:
            say(f"{name} stopped: {error}")
            break
    return done


def main(arguments):
    """Rotates the named targets, or all of them, then pushes, deploys and renews Heimdall's bindings."""
    names = list(TARGETS) if arguments == ["all"] else arguments
    if not names or any(name not in TARGETS for name in names):
        print("Usage: rotate-passphrase all | <" + "|".join(TARGETS) + ">...", file=sys.stderr)
        return 2
    names = [name for name in TARGETS if name in names]
    borg = any(TARGETS[name].get("borg") for name in names)
    last = [name for name in names if TARGETS[name].get("last")]
    done = []
    try:
        preflight()
        values = {name: TARGETS[name]["make"]() for name in names}
        if borg:
            pause_backups()
        try:
            done = rotate_all([name for name in names if name not in last], values)
            if any(TARGETS[name]["store"] for name in done):
                land()
                hosts = {host for name in done for host in TARGETS[name]["hosts"]}
                for host in DEPLOY_ORDER:
                    if host in hosts:
                        deploy(host)
                if "heimdall" in done:
                    rebind_heimdall()
        finally:
            if borg:
                resume_backups()
        # Closing the KeePassXC database also takes the SSH keys out of the agent, so nothing that needs SSH may come after this
        if len(done) == len(names) - len(last):
            done += rotate_all(last, values)
        skipped = [name for name in names if name not in done]
        say(f"finished: {', '.join(done) or 'nothing'}" + (f"; not done: {', '.join(skipped)}" if skipped else ""))
        if "odin" in done:
            say("Odin asks for its new disk passphrase at the next boot.")
        return 0 if not skipped else 1
    except RotateError as error:
        say(f"stopped: {error}")
    except KeyboardInterrupt:
        say("stopped by Ctrl+C")
    except Exception as error:  # Never let a traceback carry a value to the terminal
        say(f"stopped by an unexpected {type(error).__name__}")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
