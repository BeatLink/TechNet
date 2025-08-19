#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash gum


# https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html


prepare_workspace() {
  WORKDIR=$(mktemp -d)
  cleanup() {
    rm -rf "$WORKDIR"
  }
  trap cleanup EXIT
  INSTALL_DIR=$WORKDIR/install
  mkdir $INSTALL_DIR
  mkdir -p $INSTALL_DIR/persistent/etc/ssh/
  touch "$INSTALL_DIR/persistent/etc/ssh/ssh_host_ed25519_key"
  touch "$INSTALL_DIR/persistent/etc/ssh/ssh_initrd_host_ed25519_key"
  touch $WORKDIR/encryption.key
}
prepare_workspace

title(){
  gum style --foreground "#00ACFF" --border-foreground "#00ACFF" --border thick --align center --width 200 --margin "1 0" --padding "1 2" "$@"
}

pr() {
  gum style --foreground "#00ACFF" "$@"
}


title 'TechNet Installer' '' 'This script automatically installs NixOS to a device in the TechNet'

pr "Select the Host to Install"
HOST=$(gum choose "Ragnarok" "Heimdall" "Odin")
HOST_LOWERCASE=${HOST,,}
pr "$HOST" ""

pr "Enter the ssh address for the installation environment."
SSH_ADDRESS=$(gum input --placeholder "root@192.168.0.2")
pr "$SSH_ADDRESS" ""

pr "SSH Host Key" "Enter the host key for the new system's SSH server. This can be found in KeePassXC."
gum write > "$INSTALL_DIR/persistent/etc/ssh/ssh_host_ed25519_key"
pr ""

pr "SSH InitRD Host Key" "Enter the host key for the new system's SSH server in the initrd environment. This can be found in KeePassXC."
gum write > "$INSTALL_DIR/persistent/etc/ssh/ssh_initrd_host_ed25519_key"
pr ""

pr "Disk Encryption Key" "Enter the passphrase to encrypt the the new system's ZFS filesystem. This can be found in KeePassXC"
gum input --password > $WORKDIR/encryption.key
pr ""


pr "Setting Permissions..."
chmod -Rvf 755 $INSTALL_DIR
chmod -vf 600 "$INSTALL_DIR/persistent/etc/ssh/ssh_host_ed25519_key"
chmod -vf 600 "$INSTALL_DIR/persistent/etc/ssh/ssh_initrd_host_ed25519_key"
pr "Done" ""

FINAL_COMMAND="nix run github:nix-community/nixos-anywhere -- --extra-files "$INSTALL_DIR" --disk-encryption-keys $WORKDIR/encryption.key $WORKDIR/encryption.key --phases "kexec,disko,install" --no-substitute-on-destination --flake .#$HOST $SSH_ADDRESS"

title "Ready to Install!" "" "Final Command: $FINAL_COMMAND" "" "Work Folder Path: $WORKDIR" "" "The installation can now proceed. If you're satisfied with the changes, select Yes at the confirmation below"

gum confirm && bash -c "$FINAL_COMMAND"

