#!/usr/bin/env bash
# https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html

echo "--------------------------------------------------------- Odin Installer -----------------------------------------------------------"
echo
echo "This scripts automatically installs NixOS Odin to a laptop computer"
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
echo "environment will use to decrypt its SOPS credentials stored in this flake. This can be found in your KeePass Security database under"
echo "Online - BeatLink -> TechNet -> Laptop -> Odin SSH Login -> odin_ssh_host_ed25519_key"
echo 
read -p "Press Enter to Continue"
echo

mkdir -p $temp/persistent/etc/ssh/
chmod -Rvf 755 $temp
nano "$temp/persistent/etc/ssh/ssh_host_ed25519_key"
chmod -vf 600 "$temp/persistent/etc/ssh/ssh_host_ed25519_key"


echo "-------------------------------------------------- ZFS Decryption Key Copying ------------------------------------------------------"
echo
echo "Press enter to launch the nano text editor. Once launched, paste the contents of the passphrase that will be used by the installed" 
echo "environment to decrypt its ZFS filesystems. This can be found in your KeePass Security database under"
echo "Online - BeatLink -> TechNet -> Laptop ->  Odin Filesystem Decryption Key -> odin_zfs_decryption_passwordfile"
echo 
read -p "Press Enter to Continue"
echo

nano "/tmp/disk-1.key"



echo "--------------------------------------------------- Data Drive Partitioning -----------------------------------------------------------"
echo
echo "This script by default ignores the data drive. If you wish to format the data drive as well you MUST type YES in capital letters"
echo 
read -p "Type 'YES' to format the data drive: " input
echo

sed -i 's$#./5-disko-data-drive.nix$./5-disko-data-drive.nix$' ../modules/1-system/default.nix
if [[ $input != "YES" ]]; then
  sed -i 's$./5-disko-data-drive.nix$#./5-disko-data-drive.nix$' ../modules/1-system/default.nix
fi

echo "-------------------------------------------------------- Installation -----------------------------------------------------------"
echo
echo "The installation can now proceed. Enter the ssh host (eg root@192.168.0.2) to begin the installation"
echo 
read -p "SSH Host: " ssh_host
echo

nix run github:nix-community/nixos-anywhere -- \
  --extra-files "$temp" \
  --disk-encryption-keys /tmp/disk-1.key /tmp/disk-1.key \
  --phases "kexec,disko,install" \
  --flake ../../#Odin $ssh_host

sed -i 's$#./5-disko-data-drive.nix$./5-disko-data-drive.nix$' ../modules/1-system/default.nix
