# Data Drive
#
# Configures settings for mounting the Data Drive for backups
#
# The mount itself comes from the shared module in 0-common: /Storage is
# beatlink's, like everywhere else.
#
# Ownership is scoped to the borg tree instead. /Storage itself used to be
# borg:borg 0770 reset recursively, which meant nothing but borg could put
# anything on the drive and every boot re-chowned the entire drive. Moving the
# same recursive rule down to /Storage/Backups keeps the self-healing property
# where it is wanted and bounds the walk to the backup tree.
#
# `Z` rather than `d` deliberately: every repo under here is borg:borg (see
# 7-borg.nix), so there is no mixed-ownership subtree for a recursive chown to
# trample, and it repairs anything that ends up misowned -- including the
# intermediate directories `services.borgbackup.repos` creates with `mkdir -p`,
# which it leaves root-owned because it only chowns each repo's leaf.
#
# `d` alongside it because `Z` adjusts but never creates. tmpfiles runs at
# sysinit.target, before the repo services at multi-user.target, so on a fresh
# drive `Z` alone would find nothing to walk and the intermediates would stay
# root-owned until the *next* boot. Creating the parent up front closes that gap.
#

{
    # Queue depths, in the same spirit as Heimdall's
    # 2-server/1-system/3-filesystem.nix but not the same numbers, because the
    # drive is a worse one in a specific way.
    #
    # data-pool-Ragnarok is a single ST5000LM000 -- Seagate's 5TB 2.5", which is
    # shingled. On an SMR drive overlapping tracks cannot be rewritten in place,
    # so random writes land in a CMR staging area and are folded into the shingle
    # bands later. While that staging area has room the drive looks ordinary;
    # once it fills, writes stall for seconds at a time, which is what a load
    # average of 41 on four cores looks like when almost all of it is tasks
    # blocked in D state rather than tasks wanting the CPU.
    #
    # Nothing here makes an SMR drive good at random writes. What these do is
    # keep fewer, larger, more sequential writes in flight so the drive has
    # quieter stretches to fold in: shallow async write depth rather than deep,
    # and txg_timeout raised so a batch is committed as one larger run instead of
    # five smaller ones. Same knob, and the same reasoning, as Thor's SD card in
    # 5-phone/1-system/18-performance.nix.
    #
    # Heimdall's numbers are higher because its vdev is a two-disk CMR mirror:
    # more spindles to keep busy, and no fold-back penalty for asking.
    #
    # sync_read stays comparatively high. Those are reads something is blocked
    # on, and they should not queue behind a Syncthing scan.
    #
    # Two things this does NOT distinguish between, and both are deliberate:
    #
    #   These are module parameters and therefore global, so root-pool-Ragnarok
    #   gets them too -- and that one is an SSD, which would happily take deeper
    #   queues. Accepted rather than solved: ZFS has no per-pool form of these,
    #   both disks sit behind SATA-to-USB bridges that cap concurrency well below
    #   these numbers anyway, and the root pool is not where the contention is.
    #
    #   `rotational` reads 1 for both disks and means nothing here. A SATA-to-USB
    #   bridge does not pass the ATA identify data through, so the SSD reports as
    #   spinning. The same gap makes discard_max_bytes 0 on both, which quietly
    #   makes the `autotrim=on` set on both pools a no-op.
    boot.extraModprobeConfig = ''
        options zfs zfs_vdev_max_active=16
        options zfs zfs_vdev_async_write_max_active=2
        options zfs zfs_vdev_async_read_max_active=2
        options zfs zfs_vdev_sync_read_min_active=10
        options zfs zfs_vdev_scrub_max_active=1
        options zfs zfs_txg_timeout=15
    '';

    systemd.tmpfiles.settings."Backup-Drive"."/Storage/Backups" = {
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
