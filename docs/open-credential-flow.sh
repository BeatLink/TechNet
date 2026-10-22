#!/usr/bin/env bash
# Open Credential Flow ###############################################################################################################################
#
# Decrypts secrets/admin/credential-flow.drawio into a private runtime folder, opens it in draw.io, re-encrypts any edits, and deletes the copy.
#

set -euo pipefail

# Paths ##############################################################################################################################################
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
encrypted_path="secrets/admin/credential-flow.drawio"
work_dir="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/credential-flow.XXXXXX")"
plain_file="$work_dir/credential-flow.drawio"
trap 'rm -rf "$work_dir"' EXIT

cd "$repo_root"

# Decrypt ############################################################################################################################################
sops -d --output "$plain_file" "$encrypted_path"
checksum_before="$(sha256sum "$plain_file")"

# Open ###############################################################################################################################################
started_at="$(date +%s)"
env -u ELECTRON_RUN_AS_NODE drawio "$plain_file" > /dev/null 2>&1 || true

# A quick return means a running draw.io took the file over, so the copy must outlive this call.
if (($(date +%s) - started_at < 5)); then
    read -rp "Press Enter once the diagram is closed in draw.io... "
fi

# Re-encrypt #########################################################################################################################################
if [ "$(sha256sum "$plain_file")" != "$checksum_before" ]; then
    sops -e --filename-override "$encrypted_path" "$plain_file" > "$work_dir/encrypted"
    mv "$work_dir/encrypted" "$encrypted_path"
    echo "Edits re-encrypted into $encrypted_path"
fi
