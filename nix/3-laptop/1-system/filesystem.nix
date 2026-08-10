# Filesystem #########################################################################################################################################
#
# Points disko at the root drive. The encrypted ZFS data drive is created by hand at install and mounted by the shared module in 0-common.
#

{
    networking.hostId = "ee42298c"; # ZFS records pool ownership by host ID; the pools refuse to import if it changes
    disko.devices.disk.root-drive.device = "/dev/disk/by-id/nvme-WDC_PC_SN530_SDBPMPZ-256G-1101_22215C456623";
}
