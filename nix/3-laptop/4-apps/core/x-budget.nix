# X-Budget ###########################################################################################################################################
#
# The budget and monthly transactions app built in /Storage/Files/Projects/X-Tech-Laboratories/X-Budget, installed from its GitHub flake.
# It has no start-hidden flag yet, so it is a launcher entry rather than a login unit like X-Fitness.
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [ inputs.x-budget.packages.${pkgs.stdenv.hostPlatform.system}.desktop ];

                # Its data lives here, and the home rollback would otherwise blank it.
                persistence."/Storage/Apps/Core/X-Budget" = {
                    directories = [
                        ".config/x-budget"
                    ];
                };
            };
        };
}
