# Data Drive
#
# Mounts the encrypted ZFS data drive. Run 4-data-drive-setup.sh during
# installation to partition and create the pool before activating this config.
#

{ config, ... }:
{
    fileSystems."/Storage" = {
        device = "data-pool-${config.networking.hostName}/storage";
        fsType = "zfs";
        options = [
            "zfsutil"
            "nofail"
        ];
        neededForBoot = true;
    };
    systemd.tmpfiles.rules = [
        "d /Storage 1777 beatlink beatlink"
    ];
}
