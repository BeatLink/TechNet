# Disko ####################################################################################################################################
#
# This section declaratively describes the filesystem structure. It is used by disko during installation to format and partition the 
# installation drive. It is also used during boot to find and mount the needed partitions
#
# The disk partition structure follows the "Erase your Darlings" philosophy whereby the root filesystem is erased at every boot and rebuilt
# from the contents of the Nix store and this configuration flake 
#
# Disk partition generated with help from https://ethan.roo.ke/notes/nix-on-kimsufi/
# 
###########################################################################################################################################

{
    disko.devices.disk.root-drive.device = "/dev/disk/by-id/nvme-WDC_PC_SN530_SDBPMPZ-256G-1101_22215C456623";
}
