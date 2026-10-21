# ZFS ################################################################################################################################################
#
# ZFS support in the kernel and initrd, plus the trim and scrub timers that keep the pools healthy.
#

{ config, lib, ... }:
let
    rootPool = "root-pool-${config.networking.hostName}";
    dataPool = "data-pool-${config.networking.hostName}";
    usesZfs = config.technet.storage.backend == "zfs" || config.technet.storage.zfsDataPool;
in
{
    # Only on a host with a ZFS root or data pool, since loading the module and running its timers elsewhere costs memory and battery for nothing
    config = lib.mkIf usesZfs (
        lib.mkMerge [

            # ZFS Support ############################################################################################################################
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

            # Filesystem Maintenance #################################################################################################################
            {
                services = {
                    zfs = {
                        autoScrub.enable = true;

                        # Off: borg, Vorta, Syncthing and this flake already cover backups, and snapshots only pin freed blocks on pools that run near full
                        autoSnapshot.enable = false;
                    };
                };
            }
        ]
    );
}
