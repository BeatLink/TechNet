# X-Fitness ##########################################################################################################################################
#
# The workout, diet and body tracker built in /Storage/Files/Projects/X-Tech-Laboratories/X-Fitness, installed from its GitHub flake.
#
{
    config,
    inputs,
    pkgs,
    ...
}:
let
    x-fitness = inputs.x-fitness.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
in
{
    # The API token Claude Code sends to the X-Fitness server's MCP endpoint, made on the server's Your account page.
    sops.secrets.x_fitness_mcp_token = {
        sopsFile = "${config.technet.secrets.path}/x-fitness.yaml";
        owner = "beatlink";
    };

    technet.desktop.apps.x-fitness = {
        description = "X-Fitness";
        command = "${x-fitness}/bin/x-fitness-desktop";
        args = [ "--hidden" ];
        desktopFile = "${x-fitness}/share/applications/x-fitness.desktop";
        socket = "$HOME/.config/x-fitness/SingletonSocket";
    };

    home-manager.users.beatlink.home = {
        packages = [ x-fitness ];

        # Its data lives here, and the home rollback would otherwise blank it.
        persistence."/Storage/Apps/Core/X-Fitness" = {
            directories = [
                ".config/x-fitness"
            ];
        };
    };
}
