{ config, lib, pkgs, ... }:
{
    hardware = {
        graphics = {
            enable = true;
            enable32Bit = true;
        };
        nvidia = {
            modesetting.enable = true;
            open = false;
            nvidiaSettings = true;
            package = config.boot.kernelPackages.nvidiaPackages.beta;
            prime = {
                #offload = {
                #    enable = true;
                #    enableOffloadCmd = true;
                #};
                sync.enable = true;
                amdgpuBusId = "PCI:6:0:0";
                nvidiaBusId = "PCI:1:0:0";
            };
        };
    };
    services.xserver.videoDrivers = [ "nvidia" ];
}