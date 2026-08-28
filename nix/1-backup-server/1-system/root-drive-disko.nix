# Root Drive #########################################################################################################################################
#
# Points disko at the SSD holding the system, and declares the host ID the root pool is stamped with.
#

{
    networking.hostId = "bed2ee51"; # ZFS refuses to import a pool whose recorded host ID does not match

    disko.devices.disk.root-drive.device = "/dev/disk/by-id/ata-SATA_SSD_22020812000605";
}
