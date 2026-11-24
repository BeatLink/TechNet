# Root Drive #########################################################################################################################################
#
# Points disko at the SSD holding the system.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Disko Target ###############################################################################################################################
        # btrfs on LUKS rather than a ZFS pool: both drives were laid out this way for the Rock64 this host first ran on, whose CPU ran OpenZFS's own
        # AES-GCM as generic C. They moved to the Acer as they were, so the layout stays; x86 would be as fast on ZFS, but switching means a reformat.
        {
            technet.storage.backend = "btrfs-luks";

            disko.devices.disk.root-drive.device = "/dev/disk/by-id/ata-Dogfish_SSD_64GB_5E56255506071556041";
        }

        # Swap File ##################################################################################################################################
        # A subvolume of its own, because @root is rolled back every boot and btrfs will not snapshot a subvolume holding an active swapfile
        {
            disko.devices.disk.root-drive.content.partitions.cryptroot.content.content.subvolumes."@swap" = {
                mountpoint = "/swap";
                mountOptions = [ "noatime" ];
                swap.swapfile.size = "8G";
            };
        }
    ];
}
