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
# /Storage/Apps and /Storage/Files are not created here -- they are the shared
# desktop convention, declared in 0-common/desktop alongside the XDG directories
# that depend on them.
#
{ }
