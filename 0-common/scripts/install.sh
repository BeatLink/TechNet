#!/usr/bin/env bash
# https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html

echo "--------------------------------------------------------- TechNet Installer -----------------------------------------------------------"
echo
echo "This scripts automatically installs NixOS to a device in the TechNet"
echo


echo "---------------------------------------------------- Temporary Folder Creation -----------------------------------------------------"
echo
echo "A temporary folder will now be created to store keys and files to be copied into the final installation"
echo 

temp=$(mktemp -d)
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT


echo "---------------------------------------------------- SSH Host Key Copying ----------------------------------------------------------"
echo
echo "Press enter to launch the nano text editor. Once launched, paste the contents of the SSH ED25519 Host Key that the installed" 
echo "environment will use to decrypt its SOPS credentials stored in this flake. This can be found in your KeePass Security database."
echo 
read -p "Press Enter to Continue"
echo

mkdir -p $temp/persistent/etc/ssh/
chmod -Rvf 755 $temp
nano "$temp/persistent/etc/ssh/ssh_host_ed25519_key"
chmod -vf 600 "$temp/persistent/etc/ssh/ssh_host_ed25519_key"

echo "---------------------------------------------------- InitRD SSH Host Key Copying ----------------------------------------------------------"
echo
echo "Press enter to launch the nano text editor. Once launched, paste the contents of the SSH ED25519 InitRD Host Key that the installed" 
echo "environment will use to setup ssh in the initrd. This can be found in your KeePass Security database."
echo 
read -p "Press Enter to Continue"
echo

nano "$temp/persistent/etc/ssh/ssh_initrd_host_ed25519_key"
chmod -vf 600 "$temp/persistent/etc/ssh/ssh_initrd_host_ed25519_key"

echo "-------------------------------------------------- ZFS Decryption Key Copying ------------------------------------------------------"
echo
echo "Press enter to launch the nano text editor. Once launched, paste the contents of the passphrase that will be used by the installed" 
echo "environment to decrypt its ZFS filesystems. This can be found in your KeePass Security database"
echo 
read -p "Press Enter to Continue"
echo

nano "/tmp/disk-1.key"

echo "-------------------------------------------------------- Installation -----------------------------------------------------------"
echo
echo "The installation can now proceed. Enter the device name (eg Odin) and the ssh host (eg root@192.168.0.2) to begin the installation"
echo
read -p "Device: " hostname
echo 
read -p "SSH Host: " ssh_host
echo

nix run github:nix-community/nixos-anywhere -- \
  --extra-files "$temp" \
  --disk-encryption-keys /tmp/disk-1.key /tmp/disk-1.key \
  --phases "kexec,disko,install" \
  --no-substitute-on-destination \
  --flake ../../#$hostname \
  $ssh_host
