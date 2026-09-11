# Root Drive #########################################################################################################################################
#
# Points disko at the SSD holding the system, carries the host ID the ZFS module still asks for, and corrects the queue flags its bridge misreports.
#

{ lib, ... }:
let
    # One UNMAP descriptor per request, the bridge rejects a descriptor above 0xffff blocks of 512 bytes, and the kernel wants a multiple of the 4 KiB granularity
    maxDiscardBytes = toString (8191 * 4096);

    bridgeRules = ''
        ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="1561", ATTR{queue/rotational}="0", ATTR{queue/add_random}="0", RUN+="/bin/sh -c 'echo unmap > /sys%p/device/scsi_disk/*/provisioning_mode && echo ${maxDiscardBytes} > /sys%p/queue/discard_max_bytes'"
    '';
in
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
        # The JMS561U reports the SSD as rotational, so without this the kernel applies the readahead and seek heuristics meant for a spinning disk.
        # It also clears the provisioning bit in READ CAPACITY(16) while advertising UNMAP in its VPD pages, so the kernel never enables discard and
        # never records the bridge's 65535-block UNMAP limit; the mode is forced and the limit set by hand, in that order, because the kernel refuses a
        # discard size while the mode is still "full". Both stages carry the rule so the LUKS mapping stacks the right limits when it is first opened.
        {
            services.udev.extraRules = bridgeRules;
            boot.initrd.services.udev.rules = bridgeRules;
        }
    ];
}
