# Heroic #############################################################################################################################################
#
# Launcher for Epic, GOG and Amazon games. Games install under ~/Games/Heroic by default, with their Wine prefixes in its Prefixes folder.
#

{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [ pkgs.heroic ];
                persistence."/Storage/Apps/Fun/Heroic" = {
                    directories = [
                        ".config/heroic"
                        "Games/Heroic"
                    ];
                };
            };
        };
}
