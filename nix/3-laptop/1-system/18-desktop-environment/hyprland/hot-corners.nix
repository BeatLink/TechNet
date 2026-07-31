# Hot Corners
#
# Hyprland has no built in hot corner support, so waycorner provides them. It creates invisible layer-shell
# surfaces in the corners of each output and runs a command when the pointer enters one.
#
# Cinnamon stores its corners in org/cinnamon hotcorner-layout as an ordered list of "action:enabled:delay",
# ordered top left, top right, bottom left, bottom right. The live configuration is:
#
#   top left     expo:false:0     - disabled, so no corner is configured here
#   top right    desktop:true:100 - show desktop
#   bottom left  expo:true:100    - expo, the all workspaces overview (see ./overview.nix)
#   bottom right scale:true:100   - scale, Cinnamon's window picker for the current workspace
#
# Show desktop switches to a dedicated empty workspace and back again, so hitting the corner a second time
# returns to the workspace the user came from, matching how Cinnamon's show desktop toggles. Dispatching
# `workspace empty` alone would strand the user on a blank workspace with no way back via the corner.
#
# timeout_ms acts as the dwell time before a corner fires, equivalent to Cinnamon's per corner delay, which is
# 100ms for every enabled corner above.
#

{ ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home.packages = [ pkgs.waycorner ];

            xdg.configFile."waycorner/config.toml".text = ''
                [show-desktop]
                locations = ["top_right"]
                enter_command = ["${pkgs.hypr-show-desktop}/bin/hypr-show-desktop"]
                size = 10
                timeout_ms = 100

                [expo]
                locations = ["bottom_left"]
                enter_command = [ "${pkgs.context-launcher}/bin/context-launcher" "switch-window-all" ]
                size = 10
                timeout_ms = 100

                [scale]
                locations = ["bottom_right"]
                enter_command = [ "${pkgs.context-launcher}/bin/context-launcher" "switch-window" ]
                size = 10
                timeout_ms = 100
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
