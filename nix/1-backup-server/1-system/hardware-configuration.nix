# Hardware Configuration #############################################################################################################################
#
# The Acer Aspire E5-575 this host runs on, the drivers it needs before the disks can be unlocked, and the settings the backup drive needs. Both
# disks sit on the internal SATA ports.
#

{ lib, ... }:
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
            # Available from the very start of boot so the disks are ready when the unlock needs them
            boot.initrd.availableKernelModules = [
                "xhci_pci"
                "ahci"
                "sd_mod"
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

        # Backup Drive ###############################################################################################################################
        {
            services.udev.extraRules = ''
                # Give the drive three minutes to answer: it pauses for long stretches while rewriting, and a timeout would disconnect it mid-write
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ENV{ID_SERIAL_SHORT}=="WCJ9HXR9", ATTR{device/timeout}="180"

                # Do not use the drive's timing as a source of randomness
                ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ENV{ID_SERIAL_SHORT}=="WCJ9HXR9", ATTR{queue/add_random}="0"
            '';
        }

    ];
}
