# Data Drive
#
# This module manages the mounting of the data drive that stores user files, software data and other information.
# The data drive consists of 2 1TB Hard Drives configured for encrypted ZFS RAID 1. These settings decrypt and mount that
# storage during boot
#

{ config, ... }:
{
    # Queue depth for the data mirror.
    #
    # ZFS bypasses the kernel's block scheduler (nixpkgs' zfs module forces
    # scheduler=none on every zfs_member device for exactly that reason) and
    # schedules I/O itself, so ionice and BFQ weights do not reach these disks —
    # only ZFS's own tunables do.
    #
    # The default zfs_vdev_max_active=1000 assumes a device that can keep a deep
    # queue busy. These are 7200rpm spindles at roughly 150 IOPS, so a thousand
    # queued I/Os is a multi-second backlog: a backup or a sync walk fills the
    # queue, and every unrelated read then waits behind it. That is what left
    # txg_sync blocked for over 245s at a stretch. A shallow queue costs a little
    # streaming throughput and buys back latency for everything else.
    #
    # async_write_max_active is what bounds the writeback flood a backup
    # produces; sync_read stays comparatively high so interactive reads keep
    # jumping the queue, which is the priority split ionice could not express
    # here. scrub is pinned low so the Saturday scrub stops competing with
    # foreground work.
    boot.extraModprobeConfig = ''
        options zfs zfs_vdev_max_active=32
        options zfs zfs_vdev_async_write_max_active=4
        options zfs zfs_vdev_async_read_max_active=2
        options zfs zfs_vdev_sync_read_min_active=16
        options zfs zfs_vdev_scrub_max_active=1
    '';

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
