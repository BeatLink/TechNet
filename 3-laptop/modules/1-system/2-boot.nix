# Boot Loader ##########################################################################################################################
#
# This section manages misc boot settings
#
########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    boot = {
        supportedFilesystems = [ "zfs" ];                               # Needed for impermanence
        loader = {
            systemd-boot.enable = true;                                 # Use Systemd-Boot to manage booting
            grub.enable = false;                                        # Disable Grub since we're using Systemd-Boot
            efi.canTouchEfiVariables = true;                            # Allows setting boot order, UEFI settings, etc
        };
        initrd = {
            supportedFilesystems = [ "zfs" ];                           # Needed for impermanence
            systemd.enable = true;
        };
    };
}