# Boot ####################################################################################################################################
#
# This file contains boot loader and kernel settings
#
###########################################################################################################################################

{ config, lib, pkgs, ... }: 
{
    boot = {
        loader = {
            grub.enable = false;                            # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
            generic-extlinux-compatible.enable = true;      # Enables the generation of /boot/extlinux/extlinux.conf
        };
        initrd = {
            availableKernelModules = [ "usbhid" ];
            kernelModules = [ ];
        };
        kernelModules = [ ];
        extraModulePackages = [ ];   
        kernelParams = [
            "console=tty1"
            "loglevel=7"
            "video=HDMI-A-1:1024x768@60"
        ];
    };
}
