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
            services.xserver.videoDrivers = [ "nvidia" ]; # Keep explicit: nixos-hardware's gpu/amd and gpu/nvidia both mkDefault this, so dropping it merges "modesetting" back in, which claims the dGPU and kills the NVIDIA-G0 offload provider
            hardware.nvidia = {
                dynamicBoost.enable = true;
                powerManagement = {
                    enable = true;
                    finegrained = true;
                };
                package = config.boot.kernelPackages.nvidiaPackages.production.overrideAttrs (previous: {
                    # Drop once nixpkgs#576397 lands: patchelf 0.19 breaks these binaries when interpreter and rpath are set in one call.
                    postInstall = toString (previous.postInstall or "") + ''
                        for program in nvidia-cuda-mps-control nvidia-cuda-mps-server nvidia-smi nvidia-debugdump nvidia-powerd; do
                            if [ -e $bin/origBin/$program ]; then
                                install -m755 $bin/origBin/$program $bin/bin/$program
                                patchelf --set-rpath $out/lib:$libPath $bin/bin/$program
                                patchelf --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $bin/bin/$program
                            fi
                        done
                    '';
                });
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
