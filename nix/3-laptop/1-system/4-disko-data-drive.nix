# Data Drive
#
# Mounts the encrypted ZFS data drive. Run 4-data-drive-setup.sh during
# installation to partition and create the pool before activating this config.
#
# The mount itself comes from the shared module in 0-common; this host uses its
# defaults (beatlink-owned, 1777).
#

{
    technet.dataDrive.enable = true;
}
