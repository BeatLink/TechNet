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
        # Most TechNet hosts must not write to EFI variables: the ARM boards boot
        # through Tow-Boot and Heimdall's firmware mishandles them outright. The
        # laptop is the exception and overrides this to true so boot order and
        # other UEFI settings can be managed from the OS.
        loader = {
            efi.canTouchEfiVariables = lib.mkDefault false;
            systemd-boot = {
                enable = lib.mkDefault true;
                configurationLimit = lib.mkDefault 5;
            };
            grub.enable = lib.mkDefault false;
            timeout = lib.mkDefault 5;
        };
    };
}
