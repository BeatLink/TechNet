# Boot Loader
#
# This section manages misc boot settings
#

{ lib, ... }:
{
    boot = {
        # Enable Systemd in init ####################################################################################################################
        initrd = {
            enable = true;
            systemd.enable = true;
        };
        # Use Systemd-Boot instead of GRUB to manage booting and set the timeout to 5 ###############################################################
        # configurationLimit keeps /boot from filling up. The ESP is 512M and each
        # generation's kernel + initrd is ~40M, so an unbounded list reaches 94% full
        # at 12 generations and eventually breaks nixos-rebuild when a new kernel no
        # longer fits.
        loader = {
            systemd-boot = {
                enable = lib.mkDefault true;
                configurationLimit = lib.mkDefault 5;
            };
            grub.enable = lib.mkDefault false;
            timeout = lib.mkDefault 5;
        };
    };
}
