# Maps ###############################################################################################################################################
#
# Organic Maps on the phone itself, drawn by Mesa's software renderer because it needs GLES 3.0 and this Mali-400 offers only 2.0.
#
{ pkgs, ... }:
let
    # Without this the app aborts at startup with "OpenGL ES2 is not supported" and leaves a black window
    organicmaps_software_gl = pkgs.symlinkJoin {
        name = "organicmaps-software-gl";
        paths = [ pkgs.organicmaps ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/OMaps --set LIBGL_ALWAYS_SOFTWARE 1
        '';
    };
in
{
    # QtPositioning's geoclue2 plugin asks for a client under the application name, and geoclue hands no fix at all to an id its config does not list
    services.geoclue2.appConfig."app.organicmaps.desktop" = {
        isAllowed = true;
        isSystem = false;
    };

    home-manager.users.beatlink = {
        home = {
            packages = [
                organicmaps_software_gl
            ];

            # OMaps is where the downloaded offline maps, the bookmarks and the settings all live, kept out of the rollback
            persistence."/Storage/Apps/System/Maps" = {
                directories = [
                    ".local/share/OMaps"
                ];
            };
        };
    };
}
