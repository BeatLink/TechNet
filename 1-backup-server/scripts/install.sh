#!/usr/bin/bash

echo "Ragnarok Backup Server - SD Card Preparation Script"

if [ -z "$1" ]                                                  # Checks that the argument is specified
  then
    echo "Specify the path to the SD Card and relaunch. e.g. './install.sh /dev/sda/' ";
    lsblk;
    exit;
fi

set -x;                                                         # Prints the commands to console

FLAKEDIR=$(cd "$(dirname "$0")/../../"; pwd);                   # Set the flake path
WORKDIR="/tmp/ragnarok-workdir"                                 # Sets the Work Dir
mkdir -p "$WORKDIR" && cd "$WORKDIR";                           # Create and enter Workdir

nix build "$FLAKEDIR"#images.Ragnarok

sudo umount "$1"*; sudo sfdisk --delete "$1";  sudo partprobe "$1"; # Wipe the SD Card
sudo dd if=$WORKDIR/result/sd-image/$(ls $WORKDIR/result/sd-image) of="$1" bs=512 status=progress && sync;  # Writes the image 

mkdir -p $WORKDIR/mnt && sudo mount "$1"2 $WORKDIR/mnt
sudo mkdir -p "$WORKDIR/mnt/etc/ssh/" && sudo chmod -R 755 "$WORKDIR/mnt/etc/" 

flatpak run --command="keepassxc-cli" \                         # Exports the SSH host ed25519 Key and sets permissions
  org.keepassxc.KeePassXC \
  attachment-export \
  /media/beatlink/Storage/Files/Documents/SecurityDatabase.kdbx \
  "Backup Server SSH Login" \
  ragnarok_ssh_host_ed25519_key \
  $WORKDIR/ssh_host_ed25519_key
sudo mv $WORKDIR/ssh_host_ed25519_key "$WORKDIR/mnt/etc/ssh/ssh_host_ed25519_key"
sudo chmod 600 "$WORKDIR/mnt/etc/ssh/ssh_host_ed25519_key"
sudo chown root:root "$WORKDIR/mnt/etc/ssh/ssh_host_ed25519_key"

flatpak run --command="keepassxc-cli" \                         # Exports the SSH host RSA Key and sets permissions
  org.keepassxc.KeePassXC \
  attachment-export \
  /media/beatlink/Storage/Files/Documents/SecurityDatabase.kdbx \
  "Backup Server SSH Login" \
  ragnarok_ssh_host_rsa_key \
  $WORKDIR/ssh_host_rsa_key
sudo mv $WORKDIR/ssh_host_rsa_key "$WORKDIR/mnt/etc/ssh/ssh_host_rsa_key"
sudo chmod 600 "$WORKDIR/mnt/etc/ssh/ssh_host_rsa_key"
sudo chown root:root "$WORKDIR/mnt/etc/ssh/ssh_host_rsa_key"

echo ">> INSTALLATION COMPLETE - SD CARD READY <<"
echo "Insert the SD card and boot. Note that it may take a couple of minutes for anything to be displayed."     
echo "You may need to use a VGA to HDMI converter"

