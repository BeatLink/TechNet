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
            supportedFilesystems = [ "zfs" ];                           # Needed for impermanence
            systemd.enable = true;
        };
        supportedFilesystems = [ "zfs" ];                               # Needed for impermanence
        kernelParams = ["amd_pstate=active"];
        kernelModules = [];
        extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
        loader = {
            systemd-boot.enable = true;                                 # Use Systemd-Boot to manage booting
            grub.enable = false;                                        # Disable Grub since we're using Systemd-Boot
            efi.canTouchEfiVariables = true;                            # Allows setting boot order, UEFI settings, etc
            timeout = 0;
        };

    };
    nixpkgs.hostPlatform = "x86_64-linux";
}
