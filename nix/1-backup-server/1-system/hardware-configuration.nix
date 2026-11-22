# Hardware Configuration #############################################################################################################################
#
# The Acer Aspire E5-575 this host runs on, the drivers it needs before the disks can be unlocked, and the settings the backup drive's USB enclosure
# needs to work reliably. The root SSD sits on an internal SATA port and needs none.
#

{ lib, pkgs, ... }:
let
    # The enclosure the backup drive is plugged in through, a Sabrent JMicron one that held the root SSD on the Rock64
    dataBridge = "0583";

    # The adapter the backup drive used on the Rock64, and the spare enclosure; neither is in use, and their entries keep them usable
    formerDataBridge = "0576";
    spareBridge = "1561";

    # One setting for every adapter, because a second usb-storage.quirks on the command line replaces the first instead of adding to it
    storageQuirks = "152d:${dataBridge}:f,152d:${formerDataBridge}:u,152d:${spareBridge}:u";
in
{
    config = lib.mkMerge [

        # Platform ###################################################################################################################################
        {
            nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

            boot.kernelModules = [ "kvm-intel" ];

            hardware = {
                cpu.intel.updateMicrocode = true;
                enableRedistributableFirmware = true;
            };
        }

        # Storage ####################################################################################################################################
        {
            # Available from the very start of boot so the disks are ready when the unlock needs them, on the internal SATA ports and over USB alike
            boot.initrd.availableKernelModules = [
                "xhci_pci"
                "ahci"
                "sd_mod"
                "uas"
                "usb_storage"
            ];
        }

        # Lid and Screen #############################################################################################################################
        {
            # A laptop run as a server with its lid shut: closing the lid must not suspend it
            services.logind.settings.Login = {
                HandleLidSwitch = "ignore";
                HandleLidSwitchExternalPower = "ignore";
                HandleLidSwitchDocked = "ignore";
            };

            boot.kernelParams = [ "consoleblank=60" ]; # Turns the built-in panel off after a minute, lid open or shut
        }

        # Disk Protocol ##############################################################################################################################
        {
            boot.kernelParams = [
                # The backup drive's enclosure runs the fast USB disk protocol, where the f keeps a kernel default this list would otherwise drop. The
                # two unused adapters stay on the older, simpler one, under which they were the only reliable.
                "usb-storage.quirks=${storageQuirks}"

                # Slow down the first moments of USB setup for the unused adapters; without it they sometimes reject the setup and the drive never appears.
                # One setting for both, because a second usbcore.quirks on the command line replaces the first.
                "usbcore.quirks=152d:${spareBridge}:gn,152d:${formerDataBridge}:gn"
            ];
        }

        # Backup Drive Enclosure #####################################################################################################################
        {
            services.udev.extraRules = ''
                # Give the drive three minutes to answer: it pauses for long stretches while rewriting, and a timeout would disconnect it mid-write
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${dataBridge}", ATTR{device/timeout}="180"

                # Do not use the drive's timing as a source of randomness
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${dataBridge}", ATTR{queue/add_random}="0"

                # The bus-powered drive loses power under load, and with its write cache on every loss drops writes it already reported done
                ACTION=="add", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${dataBridge}", RUN+="${pkgs.smartmontools}/bin/smartctl -d sat -s wcache,off /dev/%k"
            '';
        }

    ];
}
