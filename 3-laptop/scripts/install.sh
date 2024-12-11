#!/usr/bin/env bash
#
# This scripts automatically installs Odin given the IP address of the install environment
#
# https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html
#

# Create Temporary folder
temp=$(mktemp -d)
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create a temporary folder to be copied to the install system
mkdir -p $temp/persistent/etc/ssh/
chmod -Rvf 755 $temp

# Copy the SSH host ed25519 Key
flatpak run --command="keepassxc-cli" org.keepassxc.KeePassXC \
  attachment-export \
  /media/beatlink/Storage/Files/Documents/SecurityDatabase.kdbx \
  "Odin SSH Login" \
  odin_ssh_host_ed25519_key \
  "$temp/persistent/etc/ssh/ssh_host_ed25519_key"
chmod -vf 600 "$temp/persistent/etc/ssh/ssh_host_ed25519_key"

# Copy the LUKS decryption Key
flatpak run --command="keepassxc-cli" org.keepassxc.KeePassXC \
  attachment-export \
  /media/beatlink/Storage/Files/Documents/SecurityDatabase.kdbx \
  "Odin Storage Drive Key" \
  odin_luks_decryption_passwordfile "/tmp/disk-1.key"

# Begin the installation
nix run github:nix-community/nixos-anywhere -- --extra-files "$temp" --disk-encryption-keys /tmp/disk-1.key /tmp/disk-1.key --phases "kexec,disko,install" --flake ../../#Odin root@$1