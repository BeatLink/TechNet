# Codecs #############################################################################################################################################
#
# The gstreamer plugin set and ffmpeg for hosts that decode or thumbnail media, behind a toggle because ffmpeg-full is a substantial closure.
#

{
    config,
    lib,
    pkgs,
    ...
}:
{
    options.technet.codecs.enable = lib.mkEnableOption "the gstreamer and ffmpeg codec set";

    config = lib.mkIf config.technet.codecs.enable {
        environment.systemPackages = with pkgs; [
            gst_all_1.gst-plugins-good
            gst_all_1.gst-plugins-bad
            gst_all_1.gst-plugins-ugly
            gst_all_1.gst-libav
            ffmpegthumbnailer
            ffmpeg
            ffmpeg-full
        ];
    };
}
