# Boot Loader ##########################################################################################################################
# This section manages misc boot settings
#######################################################################################################################################
{ config, lib, pkgs, ... }:
{
    boot = {
        supportedFilesystems = [ "btrfs" ];
        loader = {
            systemd-boot.enable = true;                                 # Use Systemd-Boot to manage booting
            grub.enable = false;                                        # Disable Grub since we're using Systemd-Boot
            efi.canTouchEfiVariables = false;                           # This laptop doesn't play nice with EFI variables (Curse you Acer!)
        };
        initrd = {
            systemd.enable = true;
        };
    };
}