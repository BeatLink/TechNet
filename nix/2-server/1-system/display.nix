{ pkgs, ... }:
{
    # Blanks the screen when idle
    boot.kernelParams = [ "consoleblank=60" ];

    # Needed for Webcam
    environment.systemPackages = with pkgs; [
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav
        ffmpegthumbnailer # Core video thumbnailer
        ffmpeg # Needed to decode most video formats
        ffmpeg-full
    ];
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
