# X-Fitness ##########################################################################################################################################
#
# The workout, diet and body tracker built in /Storage/Files/Projects/X-Tech-Laboratories/X-Fitness, installed from its GitHub flake.
#
{ config, inputs, ... }:
{
    # The API token Claude Code sends to the X-Fitness server's MCP endpoint, made on the server's Your account page.
    sops.secrets.x_fitness_mcp_token = {
        sopsFile = "${config.technet.secrets.path}/x-fitness.yaml";
        owner = "beatlink";
    };

    home-manager.users.beatlink =
        { pkgs, ... }:
        let
            x-fitness = inputs.x-fitness.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
        in
        {
            home = {
                packages = [ x-fitness ];

                # Its data lives here, and the home rollback would otherwise blank it.
                persistence."/Storage/Apps/Core/X-Fitness" = {
                    directories = [
                        ".config/x-fitness"
                    ];
                };
            };

            # A unit rather than an autostart .desktop, so this Electron app runs in a cgroup of its own, as X-Tasks does.
            systemd.user.services.x-fitness = {
                Unit = {
                    Description = "X-Fitness";
                    PartOf = [ "graphical-session.target" ];
                    Requires = [ "display.target" ];
                    After = [ "display.target" ];
                };
                Service = {
                    ExecStart = "${x-fitness}/bin/x-fitness-desktop --hidden";
                    Restart = "on-failure";
                    RestartSec = 5;
                };
                Install.WantedBy = [ "display.target" ];
            };
        };
}
