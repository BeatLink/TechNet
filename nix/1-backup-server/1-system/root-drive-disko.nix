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

        # Swap Partition #############################################################################################################################
        # The shared layout is the ESP then a pool sized to the remainder; disko places the ESP at priority 1000 and a 100% partition at 9001, so this sits between.
        {
            disko.devices.disk.root-drive.content.partitions.swap = {
                priority = 2000;
                size = "16G";
                content = {
                    type = "swap";
                    randomEncryption = true; # A fresh dm-crypt key every boot: nothing to store or unlock, and the kernel line already carries nohibernate
                };
            };
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
