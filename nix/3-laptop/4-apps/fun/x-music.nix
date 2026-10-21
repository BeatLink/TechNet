# X-Music ############################################################################################################################################
#
# The music player built in /Storage/Files/Projects/X-Tech-Laboratories/X-Music, installed from its GitHub flake.
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [
                    inputs.x-music.packages.${pkgs.stdenv.hostPlatform.system}.default
                ];

                # The library database lives here, and the home rollback would otherwise blank it.
                persistence."/Storage/Apps/Fun/X-Music" = {
                    directories = [
                        ".config/x-music"
                    ];
                };
            };
        };
}
