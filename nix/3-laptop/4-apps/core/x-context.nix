# X-Context ##########################################################################################################################################
#
# The app gathering tasks, notes, files, emails and links into contexts, built in /Storage/Files/Projects/X-Tech-Laboratories/X-Context and
# installed from its GitHub flake. Its daemon serves Claude Code's x-context MCP server on 127.0.0.1:3922.
#
{ inputs, pkgs, ... }:
let
    x-context = inputs.x-context.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
in
{
    technet.desktop.apps.x-context = {
        description = "X-Context";
        command = "${x-context}/bin/x-context-desktop";
        args = [ "--hidden" ];
        desktopFile = "${x-context}/share/applications/x-context.desktop";
        socket = "$HOME/.config/x-context/SingletonSocket";
    };

    home-manager.users.beatlink.home = {
        packages = [ x-context ];

        # Its data lives here, and the home rollback would otherwise blank it.
        persistence."/Storage/Apps/Core/X-Context" = {
            directories = [
                ".config/x-context"
            ];
        };
    };
}
