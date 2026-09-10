# Btrfs ##############################################################################################################################################
#
# The scrub timer a btrfs-luks host gets in place of the ZFS one, so its root drive still has something checking every checksum on a schedule.
#

{ config, lib, ... }:
{
    config = lib.mkIf (config.technet.storage.backend == "btrfs-luks") {
        services.btrfs.autoScrub = {
            enable = true;
            fileSystems = [ "/" ]; # One entry covers every subvolume: a scrub walks the whole container, not the mount it was asked about
        };
    };
}
