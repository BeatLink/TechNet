# Data Drive #########################################################################################################################################
#
# The 5TB backup disk: one btrfs subvolume inside a LUKS container.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Storage Mount ##############################################################################################################################
        {
            technet.storage.zfsDataPool = false; # /Storage is this drive, not the fleet's data-pool-Ragnarok

            boot.initrd.luks.devices.cryptstorage = {
                device = "/dev/disk/by-partuuid/b701e0a4-fa98-467d-afd6-36cbca0f0737";
                crypttabExtraOpts = [ "nofail" ]; 
            };

            fileSystems."/Storage" = {
                device = "/dev/mapper/cryptstorage";
                fsType = "btrfs";
                options = [
                    "subvol=@storage"
                    "compress=zstd"
                    "noatime"
                    "nofail"
                    "x-systemd.device-timeout=30s" # More time for HDD
                ];
                neededForBoot = true;
            };
        }
    ];
}
