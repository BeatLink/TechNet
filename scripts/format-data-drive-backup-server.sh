#!/usr/bin/env nix-shell
#! nix-shell -i bash -p gptfdisk zfs parted

# Inspired by https://github.com/danboid/creating-ZFS-disks-under-Linux/blob/master/README.md

echo "----------------------------------------- Data Drive Format Script -----------------------------------------"
echo
echo "This script format and prepare the data drive to store the backup files and other stateful information."
echo "This data drive will consist of a ZFS data storage pool on a GPT partition table"
echo
echo "DANGER: To prevent clashes with existing pools and mountpoints, this script MUST be run from the device in question"
echo 
echo "DANGER: The selected drive will be erased and formatted in its entirety. Double check to ensure that there is no important information on the drive"
echo 
lsblk
echo
read -p "Data Drive to Format: " DATA_DRIVE
echo

# Prints executed commands
set -x;

# Formatting Data Drive...
sudo sgdisk --zap-all $DATA_DRIVE && sudo partprobe

# Creating ZFS Partition
sudo sgdisk --new=1:0:0 --typecode=1:BF00 $DATA_DRIVE && sudo partprobe

# Get First Partition
DATA_PARTITION=${DATA_DRIVE}1

# Remove any old pools
sudo zpool destroy data-pool

# Creating ZFS Pool
sudo zpool create -f -d -m none -o feature@zstd_compress=enabled -o ashift=12 -o autotrim=on data-pool $DATA_PARTITION

sudo zpool upgrade -a

# Creating ZFS Dataset
sudo zfs create \
    -o encryption=on \
    -o keyformat=passphrase \
    -o keylocation="prompt" \
    -o xattr=sa \
    -o acltype=posix \
    -o relatime=on \
    -o com.sun:auto-snapshot=true \
    -o mountpoint=/Storage \
    data-pool/storage
