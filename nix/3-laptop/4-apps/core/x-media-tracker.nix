# X-Media-Tracker ####################################################################################################################################
#
# The movie and TV tracker built in /Storage/Files/Projects/X-Tech-Laboratories/X-Media-Tracker, installed from its GitHub flake.
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [ inputs.x-media-tracker.packages.${pkgs.stdenv.hostPlatform.system}.desktop ];

                # Its data lives here, and the home rollback would otherwise blank it.
                persistence."/Storage/Apps/Core/X-Media-Tracker" = {
                    directories = [
                        ".config/x-media-tracker"
                    ];
                };
            };
        };
}
