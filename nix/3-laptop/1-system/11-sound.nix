{ lib, pkgs, ... }:
{
    security.rtkit.enable = true;
    services = {
        pulseaudio.enable = false;
        pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
            jack.enable = true;
            wireplumber.enable = true;
        };
    };
    environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
        lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0"
            (
                with pkgs.gst_all_1;
                [
                    gst-plugins-good
                    gst-plugins-bad
                    gst-plugins-ugly
                    gst-libav
                ]
            );
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ sox ];
                persistence = {
                    "/Storage/Apps/Tools/Sox" = {
                        directories = [ ];
                        allowOther = true;
                    };
                    "/Storage/Apps/System/Pipewire" = {
                        directories = [
                            ".local/state/wireplumber"
                        ];
                        allowOther = true;
                    };
                };
            };
        };
}
