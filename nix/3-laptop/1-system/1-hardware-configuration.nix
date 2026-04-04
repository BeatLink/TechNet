{
    boot = {
        initrd = {
            availableKernelModules = [
                "nvme" # For NVMe Storage Drives
                "xhci_pci" # For USB 3 and PCI Devices
                "usbhid" # For USB Devices
                "mt7921e" # Wi-Fi Drivers
                "ideapad_laptop" # Lenovo Drivers (Function Keys, Battery Management, etc)
                "ryzen_smu"
            ];
        };
        kernelModules = [ "kvm-amd" "ryzen_smu" ]; # Virtualization for VMs
        kernelParams = [
            "amd_pstate=active" # Enables Power Management for AMD CPUs
            "pcie_aspm=off"
        ];
    };
    hardware = {
        cpu.amd.updateMicrocode = true; # Updates the CPU Microcode
        enableRedistributableFirmware = true; # Enable firmware with a license allowing redistribution.
    };
    nixpkgs.hostPlatform = "x86_64-linux"; # This laptop has a 64 bit architecture
    services = {
        thermald.enable = true;
    };
}
