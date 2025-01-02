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
            supportedFilesystems = [ "zfs" ];                           # Needed for impermanence
            systemd.enable = true;
        };
        kernelParams = [
            "amd_pstate=active"
        ];
        kernel.sysctl."kernel.sysrq" = 1;
        kernelPackages = pkgs.linuxPackages_latest;
        kernelModules = [];
        supportedFilesystems = [ "zfs" ];                               # Needed for impermanence
        loader = {
            systemd-boot.enable = true;                                 # Use Systemd-Boot to manage booting
            grub.enable = false;                                        # Disable Grub since we're using Systemd-Boot
            efi.canTouchEfiVariables = true;                            # Allows setting boot order, UEFI settings, etc
            timeout = 0;
        };

    };
    nixpkgs.hostPlatform = "x86_64-linux";
}
