{ config, lib, pkgs, ... }:
{
    hardware = {
        cpu.amd.updateMicrocode = true;
        enableRedistributableFirmware = true;
    };
    boot = {
        initrd = {
            availableKernelModules = [ 
                "nvme" 
                "xhci_pci" 
                "uas" 
                "usbhid" 
                "sd_mod"
                "mt7921e"
                "ideapad_laptop"
                "kvm-amd"
            ];
            kernelModules = ["nvidia"];
        };
        kernelParams = ["amd_pstate=active"];
        kernelModules = [];
        extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
    };
    nixpkgs.hostPlatform = "x86_64-linux";
}
