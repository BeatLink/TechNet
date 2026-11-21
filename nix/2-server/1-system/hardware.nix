{
    boot = {
        initrd = {
            availableKernelModules = [
                "xhci_pci"
                "ahci"
                "nvme"
                "sd_mod"
                "usb_storage" # The root drive sits in a USB enclosure; without these the initrd cannot see it and the root pool import fails
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
