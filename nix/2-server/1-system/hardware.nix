{
    boot = {
        initrd = {
            availableKernelModules = [
                "xhci_pci"
                "ahci"
                "nvme"
                "sd_mod"
                "usb_storage" # Unused by the internal NVMe root; kept so the root drive can still boot from a USB enclosure
                "uas"
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
