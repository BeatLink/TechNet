#!/usr/bin/env bash
# Makes a new X-Nix agent key for a host and saves its private half, encrypted, as x_nix_agent_key in the host's
# secrets/<folder>/x-nix-agent.yaml. The private half only passes through a private temporary folder that is removed
# on exit; only the public line, for services.x-nix.hosts.<host>.agent_key, is printed.
#
# Usage, from the repository's root: scripts/new-x-nix-agent-key.sh <host> <secrets folder>, such as heimdall 2-server

set -euo pipefail

host=${1:?usage: scripts/new-x-nix-agent-key.sh <host> <secrets folder>}
folder=${2:?usage: scripts/new-x-nix-agent-key.sh <host> <secrets folder>}
target="secrets/$folder/x-nix-agent.yaml"

if [ ! -d "secrets/$folder" ]; then
    echo "secrets/$folder does not exist; run this from the repository's root" >&2
    exit 1
fi
if [ -e "$target" ]; then
    echo "$target already exists; remove it first to replace the key" >&2
    exit 1
fi

umask 077
scratch=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/x-nix-agent-key.XXXXXX")
trap 'rm -rf "$scratch"' EXIT

ssh-keygen -q -t ed25519 -N "" -C "x-nix-agent-$host" -f "$scratch/key"

# The key goes in as one JSON string, which YAML reads as it is, newlines included.
python3 -I -c 'import json, sys; open(sys.argv[2], "w").write("x_nix_agent_key: " + json.dumps(open(sys.argv[1]).read()) + "\n")' "$scratch/key" "$scratch/plain.yaml"

# Encrypted for the recipients .sops.yaml gives the target's path, which needs only their public keys.
sops --encrypt --filename-override "$target" --input-type yaml --output-type yaml "$scratch/plain.yaml" > "$scratch/encrypted.yaml"
mv "$scratch/encrypted.yaml" "$target"

cat "$scratch/key.pub"
