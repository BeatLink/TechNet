#!/usr/bin/bash


echo "####################################################################################################################################"
echo "#                                                                                                                                  #"
echo "#                                     Ragnarok Backup Server - SD Card Preparation Script                                          #"
echo "#                                                                                                                                  #"
echo "####################################################################################################################################"
echo ""

# Checks that the argument is specified
if [ -z "$1" ]
  then
    echo "Specify the path to the SD Card and relaunch. e.g. './install.sh /dev/sda/' ";
    echo ""
    lsblk;
    echo ""
    exit;
fi

echo "# Performing Setups #################################################################################################################"

echo ""
echo "Configuring the Flake and Work Directory..."
FLAKEDIR=$(cd "$(dirname "$0")/../../"; pwd);                   # Set the flake path
WORKDIR="/tmp/ragnarok-workdir"                                 # Sets the Work Dir

echo ""
echo "Switching to Work Directory..."
mkdir -p "$WORKDIR" && cd "$WORKDIR";                           # Create and enter Workdir

echo ""
echo "# Installing Ragnarok ##############################################################################################################"

echo ""
echo "Generating NixOS Image..."
nix build "$FLAKEDIR"#images.Ragnarok

echo ""
echo "Flashing the Image to SD Card..."
SD_IMAGE=$(ls $WORKDIR/result/sd-image)
sudo umount "$1"*; sudo partprobe "$1"; sudo sfdisk --delete "$1"; sudo partprobe "$1";
sudo dd if=$WORKDIR/result/sd-image/$SD_IMAGE of="$1" bs=4M status=progress && sync;

echo ""
echo "# Importing SSH Host Keys for SOPS #################################################################################################"

echo ""
echo "Mounting the Filesystem and creating the folder..."
mkdir -p $WORKDIR/mnt
sudo mount "$1"2 $WORKDIR/mnt
sudo mkdir -p "$WORKDIR/mnt/etc/ssh/" && sudo chmod -R 755 "$WORKDIR/mnt/etc/" 


echo ""
echo "Copying the SSH host ed25519 Key and setting permissions..."
flatpak run --command="keepassxc-cli" org.keepassxc.KeePassXC \
  attachment-export \
  /media/beatlink/Storage/Files/Documents/SecurityDatabase.kdbx \
  "Backup Server SSH Login" \
  ragnarok_ssh_host_ed25519_key \
  $WORKDIR/ssh_host_ed25519_key
sudo mv $WORKDIR/ssh_host_ed25519_key "$WORKDIR/mnt/etc/ssh/ssh_host_ed25519_key"
sudo chmod 600 "$WORKDIR/mnt/etc/ssh/ssh_host_ed25519_key"
sudo chown root:root "$WORKDIR/mnt/etc/ssh/ssh_host_ed25519_key"

echo ""
echo "Copying the SSH host RSA Key and setting permissions..."
flatpak run --command="keepassxc-cli" org.keepassxc.KeePassXC \
  attachment-export \
  /media/beatlink/Storage/Files/Documents/SecurityDatabase.kdbx \
  "Backup Server SSH Login" \
  ragnarok_ssh_host_rsa_key \
  $WORKDIR/ssh_host_rsa_key
sudo mv $WORKDIR/ssh_host_rsa_key "$WORKDIR/mnt/etc/ssh/ssh_host_rsa_key"
sudo chmod 600 "$WORKDIR/mnt/etc/ssh/ssh_host_rsa_key"
sudo chown root:root "$WORKDIR/mnt/etc/ssh/ssh_host_rsa_key"

echo ""
echo "####################################################################################################################################"
echo "#                                                                                                                                  #"
echo "#                                           INSTALLATION COMPLETE - SD CARD READY                                                  #"
echo "#                                                                                                                                  #"
echo "# Insert the SD card and boot. Note that it may take a couple of minutes for anything to be displayed.                             #"     
echo "# You may need to use a VGA to HDMI converter                                                                                      #"
echo "#                                                                                                                                  #"
echo "####################################################################################################################################"

