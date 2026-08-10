# ZFS ################################################################################################################################################
#
# ZFS support in the kernel and initrd, plus the trim and scrub timers that keep the pools healthy.
#

{ config, lib, ... }:
let
    rootPool = "root-pool-${config.networking.hostName}";
    dataPool = "data-pool-${config.networking.hostName}";
in
{
    config = lib.mkMerge [

        # ZFS Support ################################################################################################################################
        {
            boot = {
                supportedFilesystems = [ "zfs" ];
                initrd = {
                    supportedFilesystems = [ "zfs" ];
                    systemd.services."zfs-import-${dataPool}".after = [ "zfs-import-${rootPool}.service" ]; # The data pool must import after root, otherwise the two race
                };
                zfs.forceImportRoot = false;
            };
        }

        # Filesystem Maintenance #####################################################################################################################
        {
            services = {
                fstrim.enable = true;
                zfs = {
                    trim.enable = true;
                    autoScrub.enable = true;
                };
            };
        }
    ];
}
