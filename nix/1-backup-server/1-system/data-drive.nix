# Data Drive #########################################################################################################################################
#
# Queue depths for the backup pool and ownership of the borg tree; the mount itself comes from the shared module in 0-common.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Queue Depths ###############################################################################################################################
        # data-pool-Ragnarok is one shingled drive whose stalls these shallow queues keep short; they are global, so the root SSD gets them too.
        {
            boot.extraModprobeConfig = ''
                options zfs zfs_vdev_max_active=16
                options zfs zfs_vdev_async_write_max_active=2
                options zfs zfs_vdev_async_read_max_active=2
                options zfs zfs_vdev_sync_read_min_active=10
                options zfs zfs_vdev_scrub_max_active=1
                options zfs zfs_txg_timeout=15
            '';
        }

        # Backup Tree Ownership ######################################################################################################################
        {
            systemd.tmpfiles.settings."Backup-Drive"."/Storage/Backups" = {
                # Z repairs but never creates, so d is what puts the tree there before the repo services start
                d = {
                    user = "borg";
                    group = "borg";
                    mode = "0750";
                };
                Z = {
                    user = "borg";
                    group = "borg";
                    mode = "0750";
                };
            };
        }
    ];
}
