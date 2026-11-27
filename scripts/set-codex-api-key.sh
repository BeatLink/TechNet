#!/usr/bin/env bash
# Saves an API key for CODEX on Odin, encrypted, as <key name> in secrets/3-laptop/codex.yaml, replacing one already
# there. The key is read at a hidden prompt and reaches sops only on stdin, never in argv, the history or a log; a new
# file's plain first draft lives in a private folder under the runtime directory that is removed on exit.
#
# Usage, from the repository's root: scripts/set-codex-api-key.sh [key name], anthropic_api_key unless given

set -euo pipefail

name=${1:-anthropic_api_key}
target=secrets/3-laptop/codex.yaml

if [[ ! $name =~ ^[a-z0-9_]+$ ]]; then
    echo "a key name is lowercase letters, digits and underscores, such as anthropic_api_key" >&2
    exit 1
fi
if [ ! -d "$(dirname "$target")" ]; then
    echo "$(dirname "$target") does not exist; run this from the repository's root" >&2
    exit 1
fi

IFS= read -rs -p "Paste the value for $name (hidden): " value
echo
if [ -z "$value" ]; then
    echo "Nothing was pasted; nothing changed." >&2
    exit 1
fi

# The value as one JSON string, which sops set takes and YAML reads as it is; it goes in on stdin only.
as_json() {
    printf '%s' "$value" | python3 -I -c 'import json, sys; sys.stdout.write(json.dumps(sys.stdin.read()))'
}

if [ -e "$target" ]; then
    as_json | sops set --value-stdin "$target" "[\"$name\"]"
else
    umask 077
    scratch=$(mktemp -d "${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}/codex-api-key.XXXXXX")
    trap 'rm -rf "$scratch"' EXIT
    { printf '%s: ' "$name"; as_json; printf '\n'; } > "$scratch/plain.yaml"
    # Encrypted for the recipients .sops.yaml gives the target's path, which needs only their public keys.
    sops --encrypt --filename-override "$target" --input-type yaml --output-type yaml "$scratch/plain.yaml" > "$scratch/encrypted.yaml"
    mv "$scratch/encrypted.yaml" "$target"
fi
unset value

echo "Saved $name in $target."
echo "Next: git add $target and commit it; once it lands on main, the next switch declares the engine and its key for CODEX."
