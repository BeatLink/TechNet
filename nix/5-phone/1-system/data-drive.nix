# Data drive
#
# The SD card, not the eMMC. Partition 1 carries Tow-Boot at sector 16, where the Allwinner SoC looks
# for it, and is never rewritten; partition 2 is a LUKS container holding one btrfs subvolume, mounted
# at /Storage like every other host's. See docs/thor-data-card for the ZFS layout it replaced.
#
# Unlocked by clevis on the same passphrase the root drive uses, because clevis binds one secret per
# host and feeds it to every target in technet.clevis.luksDevices; the card cannot have one of its own.
#
# No snapshots. ZFS gave them free through com.sun:auto-snapshot and btrfs has no scheduler of its own,
# and the folders worth keeping are going into the syncthing mesh instead.
#
# /Storage/Apps and /Storage/Files are not created here -- they are declared in
# 0-common/1-system/filesystems/directories.nix alongside the XDG directories that depend on them.
#
{
    technet.storage.zfsDataPool = false; # /Storage is this card, not the fleet's data-pool-Thor

    # By partuuid because the GPT is still the one the ZFS pool was made with: only p2's contents changed, so its partlabel misleadingly reads zfs-data-partition
    boot.initrd.luks.devices.cryptstorage = {
        device = "/dev/disk/by-partuuid/06625445-3637-49aa-bc36-f3a301616e0b";
        allowDiscards = true;
        crypttabExtraOpts = [ "nofail" ]; # A phone's card is removable, and without this its absence stalls the initrd rather than booting without /Storage
    };

    fileSystems."/Storage" = {
        device = "/dev/mapper/cryptstorage";
        fsType = "btrfs";
        options = [
            "subvol=@storage"
            "compress=zstd"
            "noatime"
            "discard=async"
            "nofail"
            "x-systemd.device-timeout=10s" # Bounds the wait when the card is out, rather than holding the boot for the default 90s
        ];
        neededForBoot = true; # Must stay true: clevis unlocks the device only in the initrd, so a stage 2 mount finds no key
    };
}
