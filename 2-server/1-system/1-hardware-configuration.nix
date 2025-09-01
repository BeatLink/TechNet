{
    boot = {
        initrd = {
            availableKernelModules = [
                "xhci_pci"
                "ahci"
                "sd_mod"
                "rtsx_pci_sdmmc"
            ];
        };
        kernelModules = [ "kvm-intel" ];
    };
    hardware = {
        cpu.intel.updateMicrocode = true;
        enableRedistributableFirmware = true;
    };
    nixpkgs.hostPlatform = "x86_64-linux";
}
