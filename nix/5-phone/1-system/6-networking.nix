{
    networking = {
        # Sets the hostName
        hostName = "Thor";

        # Sets the Host ID for ZFS
        hostId = "aef23b78";
        wireless.enable = false;
        networkmanager.enable = true;

        # FIXME : configure usb rndis through networkmanager in the future.
        # Currently this relies on stage-1 having configured it.
        networkmanager.unmanaged = [
            "rndis0"
            "usb0"
        ];
    };
}
