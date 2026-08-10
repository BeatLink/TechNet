# Boot Loader ########################################################################################################################################
#
# Systemd owns the whole path: systemd-boot as the EFI loader, then systemd rather than the scripted initrd for early userspace.
#

{ lib, ... }:
{
    boot.loader = {
        grub.enable = false;
        systemd-boot = {
            enable = lib.mkDefault true;
            configurationLimit = 5; # Limited to save storage space.
        };
        timeout = 5;
    };

    boot.initrd = {
        enable = true;
        systemd.enable = true;
    };
}
