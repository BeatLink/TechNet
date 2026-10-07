# Maps ###############################################################################################################################################
#
# Organic Maps on the phone itself: it is Qt, which is the one toolkit this Mali-400 accelerates, and it draws through GLES 2.0, which is all the GPU offers.
#
{ pkgs, ... }:
{
    # QtPositioning's geoclue2 plugin asks for a client under the application name, and geoclue hands no fix at all to an id its config does not list
    services.geoclue2.appConfig."app.organicmaps.desktop" = {
        isAllowed = true;
        isSystem = false;
    };

    home-manager.users.beatlink = {
        home = {
            packages = with pkgs; [
                organicmaps
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
