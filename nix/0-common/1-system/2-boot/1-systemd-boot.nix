{ lib, ... }:
{
    boot = {
        # Enable Systemd in init ####################################################################################################################
        initrd = {
            enable = true;
            systemd.enable = true;
        };
        # Use Systemd-Boot instead of GRUB to manage booting and set the timeout to 5 ###############################################################
        loader = {
            systemd-boot.enable = lib.mkDefault true;
            grub.enable = lib.mkDefault false;
            timeout = lib.mkDefault 5;
        };
    };
}
