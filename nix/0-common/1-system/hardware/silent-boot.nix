# Silent Boot ########################################################################################################################################
#
# The Plymouth splash and the quiet-boot settings that keep the kernel log off the screen behind it.
#

{ inputs, ... }:
{
    imports = [ inputs.nixos-plymouth.nixosModules.default ];

    boot.initrd.verbose = false;
    boot.consoleLogLevel = 0;
    boot.kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
    ];
}
