#!/usr/bin/env nix-shell
#! nix-shell -i bash -p gum gptfdisk zfs parted

# Inspired by https://github.com/danboid/creating-ZFS-disks-under-Linux/blob/master/README.md

title() {
    gum style --foreground "#00ACFF" --border-foreground "#00ACFF" \
        --border thick --align center --width 150 --margin "1 0" \
        --padding "1 2" "$@"
}

pr() {
    local timestamp
    timestamp=$(date +"[%H:%M:%S]")
    gum style --foreground "#00ACFF" "$timestamp $*"
}

success() {
    local timestamp
    timestamp=$(date +"[%H:%M:%S]")
    gum style --foreground "#00FF7F" "$timestamp $*"
}

fail() {
    local timestamp
    timestamp=$(date +"[%H:%M:%S]")
    gum style --foreground "#FF4C4C" "$timestamp ❌ $*"
}

run_checked() {
    local cmd="$*"
    eval "$cmd"
    if [[ $? -ne 0 ]]; then
        fail "Command failed: $cmd"
        exit 1
    fi
}

choose() {
    gum choose --item.foreground "#00ACFF" --header.foreground "#00ACFF" \
        --cursor.foreground "#00ACFF" --header "$1" "${@:2}"
}

title "Data SD Card Format Script" \
    "" \
    "This script format and prepare the SD Card to store TowBoot as well as the backup files and other stateful information." \
    "" \
    "This data drive will consist of a GPT partition table containing the Tow Boot Image as well as the encrypted ZFS data storage pool" \
    "" \
    "DANGER: The selected drive will be erased and formatted in its entirety. Double check to ensure that there is no important information on the drive"


# Get the SD Card
pr "Select the SD Card that will be formatted"
DATA_DRIVE=$(lsblk -dn -o NAME | sed 's|^|/dev/|' | gum choose)
pr "SD Card: $DATA_DRIVE" ""

# Get the Towboot Version
TOWBOOT_VERSION=$(gum input --placeholder "2023.07-007" --prompt "TowBoot Version: ")
TOWBOOT_VERSION=${TOWBOOT_VERSION:-"2023.07-007"}
pr "TowBoot Version: $TOWBOOT_VERSION"

# Prints executed commands
set -x;

# Formatting Data Drive...
sudo sgdisk --zap-all $DATA_DRIVE && sudo partprobe

# Wipe any residual Tow Boot content
sudo dd if=/dev/zero of=$DATA_DRIVE bs=32k seek=4 count=1 && sync

# Download TowBoot
wget https://github.com/Tow-Boot/Tow-Boot/releases/download/release-$TOWBOOT_VERSION/pine64-pinephoneA64-$TOWBOOT_VERSION.tar.xz

# Extract the TowBoot Archive
tar -xvf pine64-pinephoneA64-$TOWBOOT_VERSION.tar.xz

# Writes towboot to the SD Card
sudo dd if=pine64-pinephoneA64-$TOWBOOT_VERSION/shared.disk-image.img of=$DATA_DRIVE bs=1M oflag=direct,sync status=progress

# Expands the GPT Partition Table to the rest of the SD Card
echo "write" | sudo sfdisk --append $DATA_DRIVE

# Creating ZFS Partition
sudo sgdisk --new=2:0:0 --typecode=1:BF00 $DATA_DRIVE && sudo partprobe

# Get Second Partition
DATA_PARTITION=${DATA_DRIVE}2

# Unmount pools
sudo zpool export data-pool-thor

# Creating ZFS Pool
sudo zpool create -f -d -m none -o feature@zstd_compress=enabled -o ashift=12 -o autotrim=on data-pool-thor $DATA_PARTITION

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
    -o mountpoint=legacy \
    data-pool-thor/storage
