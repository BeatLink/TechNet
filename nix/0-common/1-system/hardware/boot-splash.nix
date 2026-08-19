# Boot Splash ########################################################################################################################################
#
# The Plymouth splash and the log verbosity behind it. Press Esc during boot to swap the splash for the message log.
#

{
    inputs,
    lib,
    pkgs,
    ...
}:
{
    imports = [ inputs.nixos-plymouth.nixosModules.default ];

    config = lib.mkMerge [

        # Halon Theme ################################################################################################################################
        {
            boot.plymouth = {
                theme = lib.mkOverride 75 "halon"; # Above the nixos-plymouth import's default, below the phone's portrait-theme mkForce
                themePackages = [ inputs.halon.packages.${pkgs.stdenv.hostPlatform.system}.halon-plymouth-theme ];
            };
        }

        # Log Verbosity ##############################################################################################################################
        # The console carries errors only so the splash stays clean, while udev keeps logging at info: the kernel ring buffer takes every
        # message regardless of console level, so journald still holds a full boot to read back afterwards.
        {
            boot.consoleLogLevel = 3; # Not lower: a silent console hides the panic that boot.shell_on_fail exists to catch
            boot.initrd.verbose = false;
            boot.kernelParams = [
                "systemd.show_status=false"
                "rd.systemd.show_status=false"
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
