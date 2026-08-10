# Display #
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

        # Graphics Stack #
        {
            hardware.graphics = {
                enable = true;
                enable32Bit = true;
            };
            hardware.amdgpu.initrd.enable = true; # Loads amdgpu early so the external monitor shows the password prompt
        }

        # NVIDIA dGPU #
        {
            hardware.nvidia = {
                modesetting.enable = true;
                dynamicBoost.enable = true;
                powerManagement = {
                    enable = true;
                    finegrained = true;
                };
                open = true;
                nvidiaSettings = true;
                package = config.boot.kernelPackages.nvidiaPackages.beta;
                prime = {
                    amdgpuBusId = "PCI:6:0:0";
                    nvidiaBusId = "PCI:1:0:0";
                    offload.enable = true;
                };
            };
            services.xserver.videoDrivers = [
                "modesetting"
                "nvidia"
            ];
        }

        # Render GPU Selection #
        # libglvnd reads 10_nvidia.json before 50_mesa.json, so without this the compositor and Xwayland take the dGPU and Mesa clients lose DRI3.
        {
            environment.sessionVariables.__EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
            hardware.nvidia.prime.offload.enableOffloadCmd = false;
            environment.systemPackages = [
                (pkgs.writeShellScriptBin "nvidia-offload" ''
                    export __NV_PRIME_RENDER_OFFLOAD=1
                    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
                    export __GLX_VENDOR_LIBRARY_NAME=nvidia
                    export __VK_LAYER_NV_optimus=NVIDIA_only
                    export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
                    exec "$@"
                '')
            ];
        }

        # External Monitor #
        {
            hardware.i2c.enable = true;
        }

        # Backlight #
        {
            systemd.services.set-brightness = {
                description = "Set default screen brightness";
                wantedBy = [ "multi-user.target" ];
                after = [ "multi-user.target" ];
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = ''
                        /run/current-system/sw/bin/brightnessctl set 100%
                    '';
                };
            };
        }

        # Lid Switch #
        {
            services.logind.settings.Login = {
                HandleLidSwitch = "ignore"; # Overrides the lid switch before login, which otherwise sleeps the system on the login page
                HandleLidSwitchDocked = "ignore";
            };
        }
    ];
}
