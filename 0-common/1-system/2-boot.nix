# Boot Loader
#
# This section manages misc boot settings
#

{ lib, ... }:
{
    boot = {
        kernel.sysctl."kernel.sysrq" = 1; # Enable Magic SysRq Keys
        initrd.systemd.enable = true; # Enable Systemd in init
        loader = {
            systemd-boot.enable = true; # Use Systemd-Boot to manage booting
            grub.enable = false; # Disable Grub since we're using Systemd-Boot
            timeout = lib.mkDefault 5;
        };
    };
}
