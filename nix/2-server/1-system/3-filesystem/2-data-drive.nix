# Data Drive
#
# This module manages the mounting of the data drive that stores user files, software data and other information.
# The data drive consists of 2 1TB Hard Drives configured for encrypted ZFS RAID 1. These settings decrypt and mount that
# storage during boot
#

{ config, ... }:
{
    # Put the rotational data disks on BFQ. The kernel defaults these to `none`
    # (no reordering, no priority awareness), under which both ionice and
    # systemd's IOSchedulingClass/IOWeight are silently ignored — a backup and a
    # sync job then compete with interactive reads on equal footing, which is
    # what starves the pool and leaves txg_sync blocked for minutes at a time.
    # BFQ is the only available scheduler that honours per-cgroup io weights.
    # Restricted to rotational devices; the boot SSD is left on `none`, where
    # seek-ordering buys nothing.
    services.udev.extraRules = ''
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    '';
    boot.kernelModules = [ "bfq" ];

    systemd.tmpfiles.settings."Storage" = {
        # Sets the mount point permissions
        "/Storage" = {
            d = {
                user = "beatlink";
                group = "beatlink";
                mode = "1777";
            };
        };
    };
    fileSystems."/Storage" = {
        # Mounts the drive
        device = "data-pool-${config.networking.hostName}/storage";
        fsType = "zfs";
        options = [
            "zfsutil"
            "nofail"
        ];
        neededForBoot = true;
    };
}
