# X-Tasks ############################################################################################################################################
#
# The task app built in /Storage/Files/Projects/X-Tech-Laboratories/X-Tasks, installed from its GitHub flake.
#
{ inputs, pkgs, ... }:
let
    x-tasks = inputs.x-tasks.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
    technet.desktop.apps.x-tasks = {
        description = "X-Tasks";
        command = "${x-tasks}/bin/x-tasks";
        desktopFile = "${x-tasks}/share/applications/x-tasks.desktop";
        socket = "$HOME/.config/x-tasks/SingletonSocket";
    };

    home-manager.users.beatlink.home = {
        packages = [ x-tasks ];

        # Its data lives here, and the home rollback would otherwise blank it.
        persistence."/Storage/Apps/Core/X-Tasks" = {
            directories = [
                ".config/x-tasks"
            ];
        };
    };
}
