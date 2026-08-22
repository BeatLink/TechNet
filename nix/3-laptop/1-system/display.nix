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

        # Graphics Stack #############################################################################################################################
        {
            hardware.graphics = {
                enable = true;
                enable32Bit = true;
            };
            hardware.amdgpu.initrd.enable = true;
        }

        # NVIDIA dGPU ################################################################################################################################
        {
            hardware.nvidia = {
                modesetting.enable = true;
                dynamicBoost.enable = false;
                powerManagement = {
                    enable = true;
                    finegrained = true;
                };
                open = true;
                nvidiaSettings = true;
                package = config.boot.kernelPackages.nvidiaPackages.production;
                prime = {
                    amdgpuBusId = "PCI:6:0:0";
                    nvidiaBusId = "PCI:1:0:0";
                    offload.enable = true;
                    offload.enableOffloadCmd = false;
                };
            };
            services.xserver.videoDrivers = [
                "modesetting"
                "nvidia"
            ];
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
