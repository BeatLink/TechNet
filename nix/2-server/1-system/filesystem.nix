# Filesystem
#
# Points disko at the root drive and tunes the ZFS queue depths for this host's data pool, a mirror of one SSD and one
# shingled hard disk. The mount itself comes from the shared module in 0-common.
#

{
    # ZFS requires a unique host ID to record pool ownership; it lives here
    # rather than with the network config because it is a filesystem concern.
    networking.hostId = "e5aa3553";

    disko.devices.disk.root-drive.device = "/dev/disk/by-id/ata-Dogfish_SSD_64GB_5E56255506071556041";

    # This pool runs near full, so it keeps a shorter snapshot history than the shared default; snapshots pin freed blocks and it has no room to spare
    services.zfs.autoSnapshot = {
        hourly = 12;
        daily = 5;
        weekly = 2;
        monthly = 2;
    };

    # Deep queues let the disks sort requests by head position, which is the only thing that makes the shingled drive keep up
    boot.extraModprobeConfig = ''
        options zfs zfs_vdev_max_active=32
        options zfs zfs_vdev_async_write_min_active=12
        options zfs zfs_vdev_async_write_max_active=24
        options zfs zfs_vdev_async_read_max_active=8
        options zfs zfs_vdev_sync_read_min_active=10
        options zfs zfs_vdev_sync_read_max_active=16
        options zfs zfs_vdev_scrub_min_active=8
        options zfs zfs_vdev_scrub_max_active=24
        options zfs zfs_resilver_min_time_ms=6000
    '';
}
