# Storage Directories ################################################################################################################################
#
# Odin's own directories under /Storage/Files, bind mounted onto themselves so Nemo lists them beside the drives instead of in the bookmarks.
#

{ lib, ... }:
let
    places = [
        "Projects"
        "VMs"
        "Backups"
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
            fileSystems = lib.listToAttrs (
                map (place: {
                    name = "/Storage/Files/${place}";
                    value = {
                        device = "/Storage/Files/${place}";
                        fsType = "none";
                        options = [
                            "bind"
                            "x-gvfs-show"
                            "x-gvfs-name=${place}"
                            "nofail" # The mount runs before tmpfiles, so the first boot after adding a place here skips it rather than failing
                        ];
                    };
                }) places
            );
        }
    ];
}
