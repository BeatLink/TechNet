# Hardware Configuration #############################################################################################################################
#
# Kernel modules, CPU, firmware and boot loader settings for this laptop.
#

{ lib, pkgs, ... }:
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
                kernelParams = [ "pcie_aspm=off" ];
            };
        }

        # Boot Loader ################################################################################################################################
        {
            boot.loader.efi.canTouchEfiVariables = lib.mkForce true; # Forced over 0-common's false, which otherwise wins
        }

        # CPU and Firmware ###########################################################################################################################
        {
            nixpkgs.hostPlatform = "x86_64-linux";
            boot.kernelPackages = pkgs.linuxPackages.extend (
                kernelFinal: kernelPrevious: {
                    ryzen-smu = kernelPrevious.ryzen-smu.overrideAttrs (previous: {
                        # The module aggregator needs a .ko.cer beside every external module, and this package installs its .ko by hand.
                        postInstall = (previous.postInstall or "") + ''
                            module=$out/lib/modules/${kernelFinal.kernel.modDirVersion}/kernel/drivers/ryzen_smu/ryzen_smu.ko
                            chmod u+w $module
                            ${lib.getExe pkgs.buildPackages.kmodigest} $module
                            chmod a-w $module
                        '';
                    });
                }
            );
            hardware = {
                cpu.amd.ryzen-smu.enable = true;
                enableRedistributableFirmware = true;
            };
        }
    ];
}
