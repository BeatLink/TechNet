# Notifications
#
# SwayNotificationCenter provides both notification popups and a notification history panel, filling the role
# the Raven sidebar / KDE notification applet played in the other desktop environments.
#

{ pkgs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            services.swaync = {
                enable = true;
                settings = {
                    positionX = "right";
                    positionY = "top";
                    control-center-width = 400;
                    timeout = 8;
                    timeout-low = 4;
                    timeout-critical = 0;
                    notification-window-width = 400;
                    keyboard-shortcuts = true;
                    widgets = [
                        "title"
                        "dnd"
                        "notifications"
                        "mpris"
                    ];
                };
            };

            wayland.windowManager.hyprland.settings.bind = [
                "$mod, N, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw"
            ];
        };
}
