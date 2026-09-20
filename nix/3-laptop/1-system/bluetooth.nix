{
    hardware.bluetooth = {
        enable = true; # enables support for Bluetooth
        powerOnBoot = true; # powers up the default Bluetooth controller on boot
        settings = {
            General = {
                ControllerMode = "dual"; # Enables both classic bluetooth and bluetooth low energy
                Experimental = true; # Show battery charge of Bluetooth devices
                DiscoverableTimeout = "0"; # Always discoverable
                PairableTimeout = "0"; # Always pairable
                AutoEnable = "true"; # Enable adapters on boot
            };
        };
    };
    environment.persistence."/Storage/System/Bluetooth".directories = [ "/var/lib/bluetooth" ];
}
