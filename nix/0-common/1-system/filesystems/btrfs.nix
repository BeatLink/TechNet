# Btrfs ##############################################################################################################################################
#
# The scrub timer a btrfs-luks host gets in place of the ZFS one, so every checksum it holds is still read back on a schedule.
#

{ config, lib, ... }:
{
    config = lib.mkIf (config.technet.storage.backend == "btrfs-luks") {
        services.btrfs.autoScrub = {
            enable = true;
            # One entry per LUKS container, not per subvolume: a scrub walks the whole device, so / covers @nix and @home, and /Storage is the second.
            fileSystems = [
                "/"
                "/Storage"
            ];
        };
    };
}
