# Storage Directories ################################################################################################################################
#
# Odin's own directories under /Storage/Files, bookmarked alongside the shared ones so Nemo lists them as folders rather than as drives.
#

{ lib, ... }:
let
    places = [
        "Backups"
        "Projects"
        "VMs"
    ];
in
{
    config = lib.mkMerge [

        # Directories ################################################################################################################################

        {
            systemd.tmpfiles.settings."Storage-Odin" = lib.listToAttrs (
                map (place: {
                    name = "/Storage/Files/${place}";
                    value.d = {
                        user = "beatlink";
                        group = "beatlink";
                        mode = "0755";
                    };
                }) places
            );
        }

        # Sidebar ####################################################################################################################################

        {
            technet.desktop.fileManager.bookmarks = lib.mkAfter (
                lib.concatMapStringsSep "\n" (place: "file:///Storage/Files/${place} ${place}") places
            );
        }
    ];
}
