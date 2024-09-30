{ config, lib, pkgs, modulesPath, ... }: 
{
    hardware.sensor.hddtemp = {
        enable = true;
        drives = ["/dev/disk/by-path/*"];
    };
}