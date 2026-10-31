# X-Tasks ############################################################################################################################################
#
# The task app built in /Storage/Files/Projects/X-Tech-Laboratories/X-Tasks, installed from its GitHub flake.
#
{ inputs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        let
            x-tasks = inputs.x-tasks.packages.${pkgs.stdenv.hostPlatform.system}.default;
        in
        {
            home = {
                packages = [ x-tasks ];

                # Its data lives here, and the home rollback would otherwise blank it.
                persistence."/Storage/Apps/Core/X-Tasks" = {
                    directories = [
                        ".config/x-tasks"
                    ];
                };
            };

            # A unit rather than an autostart .desktop, so this Electron app runs in a cgroup of its own, as Trilium does.
            systemd.user.services.x-tasks = {
                Unit = {
                    Description = "X-Tasks";
                    PartOf = [ "graphical-session.target" ];
                    Requires = [ "display.target" ];
                    After = [ "display.target" ];
                };
                Service = {
                    ExecStart = "${x-tasks}/bin/x-tasks";
                    Restart = "on-failure";
                    RestartSec = 5;
                };
                Install.WantedBy = [ "display.target" ];
            };
        };
}
