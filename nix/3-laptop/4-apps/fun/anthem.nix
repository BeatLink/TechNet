# Anthem #############################################################################################################################################
#
# The music player built in /Storage/Files/Projects/Coding/Anthem, installed from its GitHub flake.
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [
                    inputs.anthem.packages.${pkgs.stdenv.hostPlatform.system}.default
                ];

                # The library database lives here, and the home rollback would otherwise blank it.
                persistence."/Storage/Apps/Fun/Anthem" = {
                    directories = [
                        ".config/anthem"
                    ];
                };
            };
        };
}
