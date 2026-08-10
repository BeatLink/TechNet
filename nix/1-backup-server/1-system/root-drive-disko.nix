{
    # ZFS requires a unique host ID to record pool ownership; it lives here
    # rather than with the network config because it is a filesystem concern.
    networking.hostId = "bed2ee51";

    disko.devices.disk.root-drive.device = "/dev/disk/by-id/ata-SATA_SSD_22020812000605";
}
