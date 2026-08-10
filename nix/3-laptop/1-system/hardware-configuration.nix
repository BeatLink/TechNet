# Hardware Configuration #############################################################################################################################
#
# Kernel modules, CPU, firmware and boot loader settings for this laptop.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Kernel #####################################################################################################################################
        {
            boot = {
                initrd.availableKernelModules = [
                    "nvme"
                    "xhci_pci"
                    "usbhid"
                    "mt7921e"
                    "ideapad_laptop"
                ];
                kernelModules = [ "kvm-amd" ];
                kernelParams = [
                    "amd_pstate=active"
                    "pcie_aspm=off"
                ];
            };
        }

        # Boot Loader ################################################################################################################################
        {
            boot.loader.efi.canTouchEfiVariables = lib.mkForce true; # Forced over 0-common's false, which otherwise wins
        }

        # CPU and Firmware ###########################################################################################################################
        {
            nixpkgs.hostPlatform = "x86_64-linux";
            hardware = {
                cpu.amd = {
                    updateMicrocode = true;
                    ryzen-smu.enable = true;
                };
                enableRedistributableFirmware = true;
            };
            services.thermald.enable = true;
        }
    ];
}
