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
let
    cfg = config.technet.codecs;

    gstPlugins = with pkgs.gst_all_1; [
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
        gst-libav
    ];
in
{
    options.technet.codecs.enable = lib.mkEnableOption "the gstreamer and ffmpeg codec set";

    config = lib.mkIf cfg.enable (lib.mkMerge [

        # Codec Set ##################################################################################################################################
        {
            environment.systemPackages =
                gstPlugins
                ++ (with pkgs; [
                    ffmpegthumbnailer
                    ffmpeg
                    ffmpeg-full
                ]);

            environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
                lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" ([ pkgs.gst_all_1.gstreamer ] ++ gstPlugins);
        }

        # Thumbnail Cache ############################################################################################################################
        {
            home-manager.users.beatlink.home.persistence."/Storage/Apps/System/Codecs".directories = [
                ".cache/thumbnails/"
            ];
        }
    ]);
}
