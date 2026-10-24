# X-Tasks ############################################################################################################################################
#
# The task app built in /Storage/Files/Projects/X-Tech-Laboratories/X-Tasks, installed from its flake.
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [
                    inputs.x-tasks.packages.${pkgs.stdenv.hostPlatform.system}.default
                ];

                # Its data lives here, and the home rollback would otherwise blank it.
                persistence."/Storage/Apps/Core/X-Tasks" = {
                    directories = [
                        ".config/x-tasks"
                    ];
                };
            };
        };
}
