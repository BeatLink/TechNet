# Hardware Configuration #############################################################################################################################
#
# The Acer Aspire E5-575 this host runs on, the drivers it needs before the disks can be unlocked, and the fixes the USB-to-SATA adapters its drives
# arrived in need to work reliably. The adapter rules match on USB ids, so they do nothing for a drive moved onto an internal SATA port.
#

{ lib, pkgs, ... }:
let
    # The adapter the backup drive is plugged in through
    dataBridge = "0576";

    # The adapter the root drive is plugged in through
    rootBridge = "0583";

    # The adapter the root drive used to sit in, kept as a spare
    spareBridge = "1561";

    # One setting for every adapter, because a second usb-storage.quirks on the command line replaces the first instead of adding to it
    storageQuirks = "152d:${dataBridge}:u,152d:${rootBridge}:f,152d:${spareBridge}:u";

    # The most the root drive is asked to erase in one request: a SATA erase range holds at most 65535 sectors, and the kernel wants a multiple of 4 KiB
    maxDiscardBytes = toString (8191 * 4096);

    rootBridgeRules = ''
        # Treat the root drive as the SSD it is, and do not use its timing as a source of randomness
        ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${rootBridge}", ATTR{queue/rotational}="0", ATTR{queue/add_random}="0"

        # Let the SSD erase unused space, then cap the request size; the cap must come second, and tee is spelled out because early boot has no PATH
        ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${rootBridge}", RUN+="/bin/sh -c 'echo unmap | ${pkgs.coreutils}/bin/tee /sys%p/device/scsi_disk/*/provisioning_mode >/dev/null && echo ${maxDiscardBytes} > /sys%p/queue/discard_max_bytes'"
    '';
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
                # Use the older, simpler USB disk protocol for the backup drive's adapter, which locks up under the fast one, and for the spare, which
                # times out on commands there. The root drive's runs the fast one, where the f keeps a kernel default this list would otherwise drop.
                "usb-storage.quirks=${storageQuirks}"

                # Slow down the first moments of USB setup for these adapters; without it they sometimes reject the setup and the drive never appears.
                # One setting for both, because a second usbcore.quirks on the command line replaces the first.
                "usbcore.quirks=152d:1561:gn,152d:0576:gn"
            ];
        }

        # Backup Drive Adapter #######################################################################################################################
        {
            services.udev.extraRules = ''
                # Give the drive three minutes to answer: it pauses for long stretches while rewriting, and a timeout would disconnect it mid-write
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${dataBridge}", ATTR{device/timeout}="180"

                # Do not use the drive's timing as a source of randomness
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${dataBridge}", ATTR{queue/add_random}="0"

                # Send the largest requests the adapter accepts, so big reads need fewer round trips
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="${dataBridge}", ATTR{device/max_sectors}="1024"
            '';
        }

        # Root Drive Adapter #########################################################################################################################
        {
            # Applied in early boot as well, because the encrypted root copies these settings from the drive at the moment it is opened
            services.udev.extraRules = rootBridgeRules;
            boot.initrd.services.udev.rules = rootBridgeRules;
        }

    ];
}
