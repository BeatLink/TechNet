# Boot Splash ########################################################################################################################################
#
# The Plymouth splash and the log verbosity behind it. Press Esc during boot to swap the splash for the message log.
#

{
    inputs,
    lib,
    ...
}:
{
    imports = [ inputs.nixos-plymouth.nixosModules.default ];

    config = lib.mkMerge [

        # Log Verbosity ##############################################################################################################################
        {
            boot.consoleLogLevel = 7; # Not 8: that paints KERN_DEBUG through fbcon, which stalls boot once drm.debug is on
            boot.initrd.verbose = true;
            boot.kernelParams = [
                "systemd.show_status=true"
                "rd.systemd.show_status=true"
                "udev.log_level=info"
                "rd.udev.log_level=info"
            ];
            services.journald.rateLimitBurst = 0; # Journald drops the bulk of this verbosity at the default burst of 10000
        }

        # Recovery Shell #############################################################################################################################
        {
            boot.kernelParams = [ "boot.shell_on_fail" ];
        }
    ];
}
