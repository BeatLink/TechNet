{ pkgs, ... }:
{
    technet.codecs.enable = true; # Needed for Webcam

    hardware = {
        intel-gpu-tools.enable = true;
        graphics = {
            enable = true;
            extraPackages = [
                # VA-API decode
                pkgs.intel-media-driver
                pkgs.intel-vaapi-driver
                # Compute
                pkgs.intel-compute-runtime-legacy1
                # VDPAU
                pkgs.libvdpau-va-gl
            ];
        };
    };
}
