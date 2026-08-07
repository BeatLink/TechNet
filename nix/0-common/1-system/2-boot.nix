# Boot Loader ########################################################################################################################################

{ lib, ... }:
{
    boot = {
        initrd = {
            enable = true;
            systemd.enable = true;
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
    };
}
