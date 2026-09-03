# Filesystem
#
# This module points disko at the root drive and manages the mounting of the data drive that stores user files,
# software data and other information.
# The data drive consists of 2 1TB Hard Drives configured for encrypted ZFS RAID 1. These settings decrypt and mount that
# storage during boot
#
# The mount itself comes from the shared module in 0-common; what is left here is the queue-depth tuning, which exists
# because this host's data pool is a pair of spinning disks.
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

    # Optimizations for slower hard disk drives
    boot.extraModprobeConfig = ''
        options zfs zfs_vdev_max_active=32
        options zfs zfs_vdev_async_write_max_active=4
        options zfs zfs_vdev_async_read_max_active=2
        options zfs zfs_vdev_sync_read_min_active=16
        options zfs zfs_vdev_scrub_max_active=1
    '';
}
