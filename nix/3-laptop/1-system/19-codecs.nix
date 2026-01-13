{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav
        ffmpegthumbnailer # Core video thumbnailer
        ffmpeg # Needed to decode most video formats
    ];
    home-manager.users.beatlink = {
        home = {
            persistence = {
                "/Storage/Apps/System/Codecs" = {
                    directories = [ ".cache/thumbnails/" ];

                };
            };
        };
    };
}
