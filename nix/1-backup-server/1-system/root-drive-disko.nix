# Root Drive #########################################################################################################################################
#
# Points disko at the SSD holding the system, declares the host ID the root pool is stamped with, and corrects the queue flags its bridge misreports.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Disko Target ###############################################################################################################################
        {
            networking.hostId = "bed2ee51"; # ZFS refuses to import a pool whose recorded host ID does not match

            disko.devices.disk.root-drive.device = "/dev/disk/by-id/ata-SATA_SSD_22020812000605";
        }

        # Queue Tuning ###############################################################################################################################
        {
            # The JMS561U reports the SSD as rotational, so without this the kernel applies the readahead and seek heuristics meant for a spinning disk
            services.udev.extraRules = ''
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="1561", ATTR{queue/rotational}="0", ATTR{queue/add_random}="0"
            '';
        }
    ];
}
