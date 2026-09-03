# Data Drive #########################################################################################################################################
#
# The USB transport and queue depths for the backup pool, plus ownership of the borg tree; the mount itself comes from the shared module in 0-common.
#

{ lib, ... }:
let
    # Every JMicron bridge the data drive has been carried in; both aborted under UAS, so each one has to be named here or it comes up unquirked
    bridges = [ "0583" "0576" ];
in
{
    config = lib.mkMerge [

        # USB Transport ##############################################################################################################################
        {
            # f is not optional: a quirks parameter replaces the kernel's built-in entry for the device rather than adding to it, and that entry is NO_REPORT_OPCODES
            boot.kernelParams = [ "usb-storage.quirks=${lib.concatMapStringsSep "," (id: "152d:${id}:uf") bridges}" ];

            # The shingled drive blocks past the 30s default while rewriting a band, and the reset the kernel then issues is what suspends the pool;
            # the drive feeds no entropy worth harvesting either. Setting a scheduler here is pointless: ZFS reopens the vdev with none.
            services.udev.extraRules = lib.concatMapStringsSep "\n" (id: ''
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${id}", ATTR{device/timeout}="180"
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${id}", ATTR{queue/add_random}="0"
            '') bridges;
        }

        # Queue Depths ###############################################################################################################################
        # data-pool-Ragnarok is one shingled drive whose stalls these shallow queues keep short; a scrub queue deeper than one drove the UAS bridge into reset loops, so it stays at one.
        {
            boot.extraModprobeConfig = ''
                options zfs zfs_vdev_max_active=16
                options zfs zfs_vdev_async_write_max_active=2
                options zfs zfs_vdev_async_read_max_active=2
                options zfs zfs_vdev_sync_read_min_active=10
                options zfs zfs_vdev_scrub_max_active=1
                options zfs zfs_txg_timeout=15
                options zfs zfs_vdev_aggregation_limit=524288
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
