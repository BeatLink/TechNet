{ config, lib, pkgs, ... }:
{

    hardware.nvidia.open = false;                               # Fixes bug with suspend 
    /*boot = {
        initrd = {
            kernelModules = ["amdgpu" "nvidia"];                 # Load AMD GPU drivers to show external monitor during initrd
            systemd.strip = false;
        };
        extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
    };
    hardware = {
        graphics = {
            enable = true;
        };
        nvidia = {
            modesetting.enable = true;
            open = true;
            nvidiaSettings = true;
            package = config.boot.kernelPackages.nvidiaPackages.stable;
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
    services.xserver.videoDrivers = ["nvidia" "amdgpu"];*/
}