{ lib, ... }:
{
    boot = {
        # Enable Systemd in init ####################################################################################################################
        initrd.systemd.enable = true;

        # Use Systemd-Boot instead of GRUB to manage booting and set the timeout to 5 ###############################################################
        loader = {
            systemd-boot.enable = true;
            grub.enable = false;
            timeout = lib.mkDefault 5;
        };
    };
}
