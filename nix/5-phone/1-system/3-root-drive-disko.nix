{
    # ZFS requires a unique host ID to record pool ownership; it lives here
    # rather than with the network config because it is a filesystem concern.
    networking.hostId = "aef23b78";

    disko.devices.disk.root-drive.device = "/dev/disk/by-id/mmc-ASTCXX_0xd1002721";
}
