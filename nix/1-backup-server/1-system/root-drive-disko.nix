# Root Drive #########################################################################################################################################
#
# Points disko at the SSD holding the system, carries the host ID the ZFS module still asks for, and corrects the queue flags its bridge misreports.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Disko Target ###############################################################################################################################
        # btrfs on LUKS rather than a ZFS pool: the A53 has aes and pmull, but OpenZFS carries its own crypto and never calls the kernel crypto API, so its
        # AES-GCM runs as generic C and took 53% of this board's CPU. dm-crypt does reach the instructions -- `cryptsetup benchmark` here reads aes-xts-256
        # at 142/92 MiB/s where aes-cbc manages 31 on the same run. The backup drive followed in data-drive.nix, so no pool is left and hostId is now vestigial.
        {
            technet.storage.backend = "btrfs-luks";

            networking.hostId = "bed2ee51"; # No pool left to import, but the ZFS module is still enabled fleet-wide and asserts on a missing host ID

            disko.devices.disk.root-drive.device = "/dev/disk/by-id/ata-SATA_SSD_22020812000605";
        }

        # Swap Partition #############################################################################################################################
        # The shared layout is the ESP then a container sized to the remainder; disko places the ESP at priority 1000 and a 100% partition at 9001, so this sits between.
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
