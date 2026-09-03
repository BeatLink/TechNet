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

                    # Reads the com.sun:auto-snapshot property disko already sets; without this the property is inert and nothing is ever taken
                    autoSnapshot = {
                        enable = true;
                        frequent = 0; # These pools change in backup-sized bursts, not continuously, so quarter-hourly snapshots only add clutter
                        hourly = 24;
                        daily = 7;
                        weekly = 4;
                        monthly = 6;
                    };
                };
            };
        }
    ];
}
