{ config, lib, pkgs, ... }:
{
    hardware = {
        graphics = {
            enable = true;
            enable32Bit = true;
        };
        nvidia = {
            modesetting.enable = true;
            powerManagement = {
                enable = true;
                finegrained = true;
            };
            open = true;
            nvidiaSettings = true;
            package = config.boot.kernelPackages.nvidiaPackages.beta;
            prime = {
                amdgpuBusId = "PCI:6:0:0";
                nvidiaBusId = "PCI:1:0:0";
                offload = {
                    enable = true;
                    enableOffloadCmd = true;
                };
            };    
        };
        amdgpu.initrd.enable = true;                           # Enables Graphics in Initrd, Allows External Monitor to load for Password Entry
    };
	services.xserver.videoDrivers = [ "modesetting" "nvidia" ];
    services.logind = {
        lidSwitch = "ignore";                                   # Override lid switch before login; Fixes system going to sleep on login page
        lidSwitchDocked = "ignore";
    };
}