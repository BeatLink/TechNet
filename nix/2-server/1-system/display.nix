{ pkgs, ... }:
{
    technet.codecs.enable = true; # Needed for Webcam

    hardware = {
        intel-gpu-tools.enable = true;
        graphics = {
            enable = true;
            extraPackages = with pkgs; [
                # VA-API decode
                intel-media-driver
                intel-vaapi-driver
                # Compute
                intel-compute-runtime-legacy1
                # VDPAU
                libvdpau-va-gl
            ];
        };
    };
}
