"""Set MCP Token

Takes an X-app's API token pasted at a hidden prompt, stores it in sops and points Claude Code's MCP server for that app at it; then commits
and pushes; X-Nix switches Odin to the pushed commit, which puts the token in /run/secrets. Run it on Odin, as beatlink, from the root of the
TechNet main checkout.
A token only reaches sops on stdin, every command is a fixed argument list, and anything printed passes through a filter that masks it.
"""

import getpass
import hashlib
import json
import shlex
import subprocess
import sys
from pathlib import Path

# Plumbing ###########################################################################################################################################

DIAGNOSTIC_PREFIXES = ("Platform:", "Linux:", "Python:", "PID:", "CWD:", "sys.argv:")
SECRETS = set()


class TokenError(Exception):
    """A step failed; its message never holds a token."""


def redact(text):
    """Masks any token this run has seen, as a last guard on anything printed."""
    for value in SECRETS:
        text = text.replace(value, "<redacted>")
    return text


def say(message):
    """Prints a progress line."""
    print(redact(f"set-mcp-token: {message}"), flush=True)


def secret(value):
    """Registers a value as secret so it can never be printed, and returns it."""
    if value:
        SECRETS.add(value)
    return value


def digest(value):
    """A hash of a value, for comparing two secrets without showing either."""
    return hashlib.sha256(value.encode()).hexdigest()


def run(argv, data=None):
    """Runs a command with data on stdin and returns its output without printing it."""
    result = subprocess.run(argv, input=data, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        lines = [line for line in result.stderr.strip().splitlines() if line.strip() and not line.startswith(DIAGNOSTIC_PREFIXES)]
        raise TokenError(f"{shlex.join(argv)} failed: {redact((lines or ['no error output'])[-1])}")
    return result.stdout


# Apps ###############################################################################################################################################

# Each app: its name on the page, where sops keeps its token, and the MCP endpoint the token opens.
APPS = {
    "x-fitness": dict(title="X-Fitness", file="secrets/3-laptop/x-fitness.yaml", key="x_fitness_mcp_token", url="https://fitness.heimdall.technet/api/mcp"),
    "x-nix": dict(title="X-Nix", file="secrets/3-laptop/claude-mcp.yaml", key="x_nix_mcp_token", url="https://nix.heimdall.technet/api/mcp"),
    "x-backups": dict(title="X-Backups", file="secrets/3-laptop/claude-mcp.yaml", key="x_backups_mcp_token", url="https://backups.heimdall.technet/api/mcp"),
    "x-media-tracker": dict(
        title="X-Media-Tracker", file="secrets/3-laptop/claude-mcp.yaml", key="x_media_tracker_mcp_token", url="https://media-tracker.heimdall.technet/api/mcp"
    ),
}


def prompt_token(app):
    """Asks for an app's token at a hidden prompt."""
    while True:
        value = getpass.getpass(f"Paste the {app['title']} token from its Your account page (hidden): ").strip()
        if value:
            return secret(value)
        print("Nothing was pasted; try again.")


# Sops ###############################################################################################################################################


def sops_store(file, key, value):
    """Stores a value in a sops file, then reads it back and compares hashes."""
    run(["sops", "set", "--value-stdin", file, f'["{key}"]'], data=json.dumps(value))
    if digest(secret(run(["sops", "--decrypt", "--extract", f'["{key}"]', file]))) != digest(value):
        raise TokenError(f"{file} {key} did not read back as written")
    say(f"stored {key} in {file}")


# Claude Code ########################################################################################################################################


def register(name, app):
    """Points Claude Code's user-scope MCP server for an app at its endpoint, with a headers helper that reads the token from /run/secrets."""
    subprocess.run(["claude", "mcp", "remove", "-s", "user", name], capture_output=True, check=False)
    server = {"type": "http", "url": app["url"], "headersHelper": f"mcp-token-header {app['key']}"}
    run(["claude", "mcp", "add-json", "-s", "user", name, json.dumps(server)])
    say(f"registered {name} with Claude Code")


# Landing ############################################################################################################################################


def land(names, files):
    """Commits the token files and pushes, rebasing onto anything that landed meanwhile; only those files changed here."""
    run(["git", "add", "--", *files])
    run(["git", "commit", "-q", "-m", f"chore(secrets): set the MCP tokens for {', '.join(names)}", "--", *files])
    try:
        run(["git", "push", "-q", "origin", "HEAD:main"])
    except TokenError:
        run(["git", "pull", "-q", "--rebase", "origin", "main"])
        run(["git", "push", "-q", "origin", "HEAD:main"])
    say("pushed")


# Main ###############################################################################################################################################


def preflight(files):
    """Checks it runs from an up-to-date TechNet main checkout whose token files have no uncommitted changes, fast-forwarding it if it is behind."""
    if not (Path(".sops.yaml").is_file() and Path("secrets").is_dir()):
        raise TokenError("run this from the root of the TechNet checkout")
    if run(["git", "rev-parse", "--abbrev-ref", "HEAD"]).strip() != "main":
        raise TokenError("check out main first")
    if run(["git", "status", "--porcelain", "--", *files]).strip():
        raise TokenError(f"{' '.join(files)} has uncommitted changes; commit or discard them first")
    run(["git", "fetch", "-q", "origin"])
    run(["git", "merge", "-q", "--ff-only", "origin/main"])


def main(arguments):
    """Sets the named apps' tokens, or all of them, then registers each with Claude Code and pushes."""
    names = list(APPS) if arguments == ["all"] else arguments
    if not names or any(name not in APPS for name in names):
        print("Usage: set-mcp-token all | <" + "|".join(APPS) + ">...", file=sys.stderr)
        return 2
    names = [name for name in APPS if name in names]
    files = sorted({APPS[name]["file"] for name in names})
    try:
        preflight(files)
        tokens = {name: prompt_token(APPS[name]) for name in names}
        for name in names:
            sops_store(APPS[name]["file"], APPS[name]["key"], tokens[name])
        for name in names:
            register(name, APPS[name])
        land(names, files)
        say(f"finished: {', '.join(names)}; restart Claude Code once X-Nix has switched Odin to connect")
        return 0
    except TokenError as error:
        say(f"stopped: {error}")
    except KeyboardInterrupt:
        say("stopped by Ctrl+C")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
