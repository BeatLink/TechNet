{ config, lib, pkgs, ... }:
{
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = ["nvidia" "amdgpu"];
    hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        prime = {
            offload = {
			    enable = true;
			    enableOffloadCmd = true;
		    };
            amdgpuBusId = "PCI:6:0:0";
            nvidiaBusId = "PCI:1:0:0";
        };
    };
}