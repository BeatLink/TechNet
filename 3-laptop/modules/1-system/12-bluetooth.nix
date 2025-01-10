{ config, lib, pkgs, modulesPath, ... }: 
{  
    hardware.bluetooth = {
        enable = true;                                  # enables support for Bluetooth
        powerOnBoot = true;                             # powers up the default Bluetooth controller on boot
    };
}