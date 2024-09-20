# Boot ####################################################################################################################################
{ config, lib, pkgs, ... }: {
    boot.loader = {
        grub.enable = false;                            # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
        generic-extlinux-compatible.enable = true;      # Enables the generation of /boot/extlinux/extlinux.conf
    };    
}
