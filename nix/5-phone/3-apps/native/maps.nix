# Maps ###############################################################################################################################################
#
# Pure Maps and the offline server behind it, both on the phone itself: Qt Quick is the one toolkit this Mali-400 accelerates, and navigation is
# wanted exactly where the link is not.
#
{ lib, pkgs, ... }:
{
    # QtPositioning's geoclue2 plugin asks for a client under the application name, and geoclue hands no fix at all to an id its config does not list
    services.geoclue2.appConfig.pure-maps = {
        isAllowed = true;
        isSystem = false;
    };

    home-manager.users.beatlink = {
        home = {
            packages = with pkgs; [
                pure-maps
                osmscout-server
                espeak-ng # Pure Maps speaks its directions through whichever of espeak, flite, mimic or pico2wave it finds on PATH
            ];

            # Map downloads are gigabytes; this is the directory the server offers on first run, kept out of the rollback rather than in it
            persistence."/Storage/Apps/System/Maps" = {
                directories = [
                    "Maps.OSM"
                    ".config/osmscout-server"
                    ".config/pure-maps"
                    ".local/share/pure-maps"
                ];
            };
        };

        # Upstream ships this and nixpkgs drops it; without it Pure Maps cannot start the server, and offline mode works only while its window is open
        xdg.dataFile."dbus-1/services/io.github.rinigus.OSMScoutServer.service".text = ''
            [D-BUS Service]
            Name=io.github.rinigus.OSMScoutServer
            Exec=${lib.getExe' pkgs.osmscout-server "osmscout-server"} --dbus-activated --quiet
        '';
    };
}
