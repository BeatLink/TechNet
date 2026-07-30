# Codecs
#
# The gstreamer plugin set and ffmpeg, for hosts that decode or thumbnail media.
# The laptop needs them for playback and file-manager thumbnails, the server for
# its webcam and media services.
#
# Behind a toggle rather than on by default: ffmpeg-full alone is a substantial
# closure, and the headless backup server and the phone have no use for any of it.
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
            ffmpegthumbnailer # Core video thumbnailer
            ffmpeg # Needed to decode most video formats
            ffmpeg-full
        ];
    };
}
