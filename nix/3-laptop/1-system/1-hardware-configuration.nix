{
    boot = {
        initrd = {
            availableKernelModules = [ 
                "nvme"                                                  # For NVMe Storage Drives
                "xhci_pci"                                              # For USB 3 and PCI Devices
                "usbhid"                                                # For USB Devices
                "mt7921e"                                               # Wi-Fi Drivers
                "ideapad_laptop"                                        # Lenovo Drivers (Function Keys, Battery Management, etc)
            ];
        };
        kernelModules = [ "kvm-amd" ];                                  # Virtualization for VMs
        kernelParams = [
            "amd_pstate=active"                                         # Enables Power Management for AMD CPUs
        ];
    };
    hardware = {
        cpu.amd.updateMicrocode = true;                                 # Updates the CPU Microcode
        enableRedistributableFirmware = true;                           # Enable firmware with a license allowing redistribution.
    };
    nixpkgs.hostPlatform = "x86_64-linux";                              # This laptop has a 64 bit architecture
}
