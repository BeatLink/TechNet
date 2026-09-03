# Data drive
#
# The SD card, not the eMMC. Partition 1 carries Tow-Boot; partition 2 is
# `data-pool-Thor`, whose `storage` dataset mounts at /Storage like every other
# host's.
#
# Unlocked by clevis against tang, which is why the pool's passphrase has to be
# the same `zfs_passphrase` the root pool uses -- clevis binds one secret per
# host and feeds it to every dataset in `technet.clevis.datasets`. The card was
# originally formatted with its own separate passphrase, which no amount of
# configuration could have made work.
#
# `nofail` in the shared module matters more here than elsewhere: this is a
# phone, and the card is removable.
#
# /Storage/Apps and /Storage/Files are not created here -- they are declared in
# 0-common/1-system/filesystems/directories.nix alongside the XDG directories that
# depend on them.
#
{
    # An SD card in a phone has no room for the shared default's history, and its contents are a mirror of the mesh rather than a sole copy
    services.zfs.autoSnapshot = {
        hourly = 6;
        daily = 3;
        weekly = 1;
        monthly = 1;
    };
}
