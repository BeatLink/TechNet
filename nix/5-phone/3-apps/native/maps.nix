# Maps ###############################################################################################################################################
#
# Pure Maps on the phone itself: Qt Quick is the one toolkit this Mali-400 accelerates, so it draws through mapbox-gl-qml rather than in software.
#
{ pkgs, ... }:
{
    # QtPositioning's geoclue2 plugin asks for a client under the application name, and geoclue hands no fix at all to an id its config does not list
    services.geoclue2.appConfig.pure-maps = {
        isAllowed = true;
        isSystem = false;
    };

    home-manager.users.beatlink = {
        # Online providers only: osmscout-server aborts on startup here, its bundled Valhalla configuration being older than the library it links
        home = {
            packages = with pkgs; [
                pure-maps
                espeak-ng # Pure Maps speaks its directions through whichever of espeak, flite, mimic or pico2wave it finds on PATH
            ];

            # Maps is the directory the offline server downloads into, kept out of the rollback for when there is one that runs
            persistence."/Storage/Apps/System/Maps" = {
                directories = [
                    "Maps"
                    ".config/pure-maps"
                    ".local/share/pure-maps"
                ];
            };
        };
    };
}
