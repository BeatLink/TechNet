# X-Context ##########################################################################################################################################
#
# The app gathering tasks, notes, files, emails and links into contexts, built in /Storage/Files/Projects/X-Tech-Laboratories/X-Context and
# installed from its GitHub flake. Its daemon serves Claude Code's x-context MCP server on 127.0.0.1:3922.
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        let
            x-context = inputs.x-context.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
        in
        {
            home = {
                packages = [ x-context ];

                # Its data lives here, and the home rollback would otherwise blank it.
                persistence."/Storage/Apps/Core/X-Context" = {
                    directories = [
                        ".config/x-context"
                    ];
                };
            };

            # A unit rather than an autostart .desktop, so this Electron app runs in a cgroup of its own, as X-Tasks does.
            systemd.user.services.x-context = {
                Unit = {
                    Description = "X-Context";
                    PartOf = [ "graphical-session.target" ];
                    Requires = [ "display.target" ];
                    After = [ "display.target" ];
                };
                Service = {
                    ExecStart = "${x-context}/bin/x-context-desktop --hidden";
                    Restart = "on-failure";
                    RestartSec = 5;
                };
                Install.WantedBy = [ "display.target" ];
            };
        };
}
