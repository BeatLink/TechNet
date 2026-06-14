#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash gum zfs


# Inspired by https://github.com/danboid/creating-ZFS-disks-under-Linux/blob/master/README.md

title(){
  gum style --foreground "#00ACFF" --border-foreground "#00ACFF" --border thick --align center --width 150 --margin "1 0" --padding "1 2" "$@"
}

pr() {
  gum style --foreground "#00ACFF" "$@"
}


title "Data Drive Format Script" \
    "" \
    "This script formats and prepare ZFS data drives for TechNet devices to store stateful information." \
    "" \
    "This script is compatible with Ragnarok, Heimdall and Odin" \
    "" \
    "DANGER: To prevent clashes with existing pools and mountpoints, this script MUST be run from the device in question" \
    "" \
    "DANGER: The selected drives will be erased and formatted in its entirety. Double check to ensure that there is no important information on the drive"

# Find out if user is configuring RAID 1
pr "Will you be using multiple drives in RAID 1?"
RAID_SETUP_ENABLED=$(gum choose "Yes" "No")

if [ "$RAID_SETUP_ENABLED" = "Yes" ]; then

    # Get the first drive to format from the user
    pr "Select the first drive that will be formatted"
    DATA_DRIVE=$(lsblk -dn -o NAME | sed 's|^|/dev/|' | gum choose)
    pr "Drive 1: $DATA_DRIVE" ""

    # Get the second drive to format from the user
    pr "Select the second drive that will be used"
    MIRROR_DRIVE=$(lsblk -dn -o NAME | sed 's|^|/dev/|' | gum choose)
    pr "Drive 2: $MIRROR_DRIVE" ""

else

    # Get the drive to format from the user
    pr "Select the drive that will be formatted"
    DATA_DRIVE=$(lsblk -dn -o NAME | sed 's|^|/dev/|' | gum choose)
    pr "Data Drive: $DATA_DRIVE" ""

fi

# Confirm formatting
pr "Ready to to begin formatting."


gum confirm "DANGER! THE ABOVE DRIVE(S) WILL BE FORMATTED IN THEIR ENTIRETY! ARE YOU SURE YOU WISH TO PROCEED?" && \
gum confirm "ONE LAST CHANCE! ARE YOU ABSOLUTELY SURE?" 




bash -c "$FINAL_COMMAND"






echo formatting drive

if [ "$RAID_SETUP_ENABLED" = "Yes" ]; then
echo adding mirror
fi





: <<'END_COMMENT'

# Prints executed commands
set -x;

# Creating ZFS Pool
sudo zpool create -f -d -m none -o feature@zstd_compress=enabled -o ashift=12 -o autotrim=on data-pool $DATA_DRIVE

# Upgrade the ZFS Pool
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

# sudo zfs set aclmode=passthrough data-pool/storage
# sudo zfs set aclinherit=passthrough data-pool/storage



# Format and attach the mirror drive
sudo zpool attach data-pool $DATA_DRIVE $MIRROR_DRIVE

END_COMMENT