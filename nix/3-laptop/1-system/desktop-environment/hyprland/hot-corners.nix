# Hot Corners
#
# Hyprland has no built in hot corner support, so waycorner provides them. It creates invisible layer-shell
# surfaces in the corners of each output and runs a command when the pointer enters one.
#
# The corner assignments mirror the KDE setup this system replaces (see ../kde/hot-corners.nix):
#   top left     - Overview, showing every window on the current workspace
#   bottom left  - Window switcher, the closest equivalent to KDE's Present Windows
#   top right    - Show desktop
#
# timeout_ms acts as the dwell time before a corner fires, equivalent to KDE's ElectricBorderDelay. It is kept
# high enough that merely passing through a corner on the way to something else does not trigger it.
#

{ pkgs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home.packages = [ pkgs.waycorner ];

            xdg.configFile."waycorner/config.toml".text = ''
                [overview]
                locations = ["top_left"]
                enter_command = ["${pkgs.hyprland}/bin/hyprctl", "dispatch", "overview:toggle"]
                size = 10
                timeout_ms = 250

                [window-switcher]
                locations = ["bottom_left"]
                enter_command = ["${pkgs.rofi}/bin/rofi", "-show", "window"]
                size = 10
                timeout_ms = 250

                [show-desktop]
                locations = ["top_right"]
                enter_command = ["${pkgs.hyprland}/bin/hyprctl", "dispatch", "workspace", "empty"]
                size = 10
                timeout_ms = 250
            '';

            systemd.user.services.waycorner = {
                Unit = {
                    Description = "Hot corners for Hyprland";
                    PartOf = [ "graphical-session.target" ];
                    After = [ "graphical-session.target" ];
                };
                Service = {
                    ExecStart = "${pkgs.waycorner}/bin/waycorner";
                    Restart = "on-failure";
                };
                Install.WantedBy = [ "graphical-session.target" ];
            };
        };
}
