# Pix natively on the phone rather than on Heimdall over waypipe.
#
# An X-Apps GTK3 viewer, so it rasterises through cairo instead of asking the Mali-400 for the GLES 3.0 it cannot give -- see toolkit-comparison.nix.
# The waypipe copy in 3-apps/desktop stays alongside it, so the two can be compared on the same pictures.
#
{ pkgs, ... }:
{
    home-manager.users.beatlink = {
        home = {
            packages = [ pkgs.pix ];

            # On the SD card, whose pool is still ZFS aes-256-gcm: settings and thumbnails do not get the root drive's accelerated crypto
            persistence."/Storage/Apps/System/Pix" = {
                directories = [
                    ".config/pix"
                    ".local/share/pix"
                ];
            };
        };
    };
}
