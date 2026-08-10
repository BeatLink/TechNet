# Boot ###############################################################################################################################################
#
# The boot loader plus the Plymouth splash and the quiet-boot settings that keep the kernel log off the screen behind it.
#

{ lib, inputs, ... }:
{
    imports = [ inputs.nixos-plymouth.nixosModules.default ];

    boot = {
        initrd = {
            enable = true;
            systemd.enable = true;
            verbose = false;
        };
        loader = {
            efi.canTouchEfiVariables = false; # Tow-Boot on the ARM boards and Heimdall's firmware break if written to; only the laptop overrides this
            systemd-boot = {
                enable = lib.mkDefault true;
                configurationLimit = 5; # Limited to save storage space.
            };
            grub.enable = false;
            timeout = 5;
        };

        # Silent Boot ################################################################################################################################
        consoleLogLevel = 0;
        kernelParams = [
            "quiet"
            "splash"
            "boot.shell_on_fail"
            "loglevel=3"
            "rd.systemd.show_status=false"
            "rd.udev.log_level=3"
            "udev.log_priority=3"
        ];
    };
}
