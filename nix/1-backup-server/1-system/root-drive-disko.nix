# Root Drive #########################################################################################################################################
#
# Points disko at the SSD holding the system; the bridge's quirks live in hardware-configuration.nix.
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

        # Swap Partition #############################################################################################################################
        # The shared layout is the ESP then a container sized to the remainder; disko places the ESP at priority 1000 and a 100% partition at 9001, so this sits between.
        #{
        #    disko.devices.disk.root-drive.content.partitions.swap = {
        #        priority = 2000;
        #        size = "16G";
        #        content = {
        #            type = "swap";
        #            randomEncryption = true; # A fresh dm-crypt key every boot: nothing to store or unlock, and the kernel line already carries nohibernate
        #        };
        #    };
        #}
    ];
}
