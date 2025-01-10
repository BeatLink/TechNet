{ config, lib, pkgs, modulesPath, ... }: 
{  
    hardware.bluetooth = {
        enable = true;                                  # enables support for Bluetooth
        powerOnBoot = true;                             # powers up the default Bluetooth controller on boot
        settings.General.ControllerMode = "bredr";      # Disables bluetooth low energy. Fixes a current bug in mediatek wifi drivers
    };
}