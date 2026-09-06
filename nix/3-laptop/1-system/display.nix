# Display ############################################################################################################################################
#
# Graphics drivers for the AMD iGPU and the NVIDIA dGPU, plus the screen backlight and the lid switch.
#

{
    config,
    lib,
    pkgs,
    ...
}:
{
    config = lib.mkMerge [

        # NVIDIA dGPU ################################################################################################################################
        {
            hardware.nvidia = {
                dynamicBoost.enable = true;
                powerManagement = {
                    enable = true;
                    finegrained = true;
                };
                package = config.boot.kernelPackages.nvidiaPackages.production;
            };
        }

        # External Monitor ###########################################################################################################################
        {
            hardware.i2c.enable = true;
        }

        # Backlight ##################################################################################################################################
        {
            systemd.services.set-brightness = {
                description = "Set default screen brightness";
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${pkgs.brightnessctl}/bin/brightnessctl set 100%";
                };
            };
        }

        # Lid Switch #################################################################################################################################
        {
            services.logind.settings.Login = {
                HandleLidSwitch = "ignore"; # The greeter suspends on lid close even when docked, so ignoring only the docked case is not enough
                HandleLidSwitchDocked = "ignore";
            };
        }
    ];
}
