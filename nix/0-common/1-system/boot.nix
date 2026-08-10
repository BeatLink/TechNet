# Boot ###############################################################################################################################################
#
# The boot loader plus the Plymouth splash and the quiet-boot settings that keep the kernel log off the screen behind it.
#

{ lib, inputs, ... }:
{
    imports = [ inputs.nixos-plymouth.nixosModules.default ];

    config = lib.mkMerge [

        # UEFI #######################################################################################################################################
        {
            boot.loader.efi.canTouchEfiVariables = false; # Tow-Boot on the ARM boards and Heimdall's firmware break if written to; only the laptop overrides this
        }

        # Systemd Boot ###############################################################################################################################
        # Systemd owns the whole path: systemd-boot as the EFI loader, then systemd rather than the scripted initrd for early userspace.
        {
            boot.loader = {
                grub.enable = false;
                systemd-boot = {
                    enable = lib.mkDefault true;
                    configurationLimit = 5; # Limited to save storage space.
                };
                timeout = 5;
            };
            boot.initrd = {
                enable = true;
                systemd.enable = true;
            };
        }

        # Silent Boot ################################################################################################################################
        {
            boot.initrd.verbose = false;
            boot.consoleLogLevel = 0;
            boot.kernelParams = [
                "quiet"
                "splash"
                "boot.shell_on_fail"
                "loglevel=3"
                "rd.systemd.show_status=false"
                "rd.udev.log_level=3"
                "udev.log_priority=3"
            ];
        }
    ];
}
