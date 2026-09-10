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
                    # The data pool must import after root, otherwise the two race; a btrfs-luks host has no root pool to order against
                    systemd.services = lib.mkIf (config.technet.storage.backend == "zfs") {
                        "zfs-import-${dataPool}".after = [ "zfs-import-${rootPool}.service" ];
                    };
                };
                zfs.forceImportRoot = false;
            };
        }

        # Filesystem Maintenance #####################################################################################################################
        {
            services = {
                zfs = {
                    autoScrub.enable = true;

                    # Reads the com.sun:auto-snapshot property disko already sets; without this the property is inert and nothing is ever taken
                    # mkDefault throughout: a host whose pool runs near full lowers these in its own module
                    autoSnapshot = {
                        enable = true;
                        frequent = lib.mkDefault 0; # These pools change in backup-sized bursts, not continuously, so quarter-hourly snapshots only add clutter
                        monthly = lib.mkDefault 6;
                    };
                };
            };

            # frequent is 0 everywhere, and the timer still fires quarter-hourly to keep nothing; on the phone that is a wakeup for no reason
            systemd.timers.zfs-snapshot-frequent.enable = false;
        }
    ];
}
