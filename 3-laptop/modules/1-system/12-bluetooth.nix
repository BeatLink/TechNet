{  
    hardware.bluetooth = {
        enable = true;                                  # enables support for Bluetooth
        powerOnBoot = true;                             # powers up the default Bluetooth controller on boot
        settings = {
            General = {
                ControllerMode = "bredr";      # Disables bluetooth low energy. Fixes a current bug in mediatek wifi drivers
                Experimental = true;            # Show battery charge of Bluetooth devices
                DiscoverableTimeout = "0";  # Always discoverable
                PairableTimeout = "0";     # Always pairable
                AutoEnable = "true";       # Enable adapters on boot
            };
        };
    };
}