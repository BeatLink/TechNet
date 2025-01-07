# Boot Loader ##########################################################################################################################
#
# This section manages misc boot settings
#
########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    boot = {
        kernelModules = [];
        kernelPackages = pkgs.linuxPackages_latest;
        kernel.sysctl."kernel.sysrq" = 1;
        initrd = {
            systemd.enable = true;
        };
        loader = {
            systemd-boot.enable = true;                                 # Use Systemd-Boot to manage booting
            grub.enable = false;                                        # Disable Grub since we're using Systemd-Boot
            efi.canTouchEfiVariables = true;                            # Allows setting boot order, UEFI settings, etc
            timeout = lib.mkDefault 5;
        };
    };
}