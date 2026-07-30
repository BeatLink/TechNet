# Waybar
#
# Waybar replaces the KDE panels. The layout mirrors the top panel from the KDE config: launcher on the left,
# clock in the centre and a system tray on the right.
#

{ pkgs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            programs.waybar = {
                enable = true;
                systemd.enable = false; # Started via exec-once so it restarts with the compositor
                settings.mainBar = {
                    layer = "top";
                    position = "top";
                    height = 32;
                    spacing = 8;
                    modules-left = [
                        "hyprland/workspaces"
                        "hyprland/window"
                    ];
                    modules-center = [ "clock" ];
                    modules-right = [
                        "tray"
                        "pulseaudio"
                        "bluetooth"
                        "network"
                        "backlight"
                        "battery"
                    ];

                    "hyprland/workspaces" = {
                        format = "{id}";
                        on-click = "activate";
                    };
                    "hyprland/window" = {
                        max-length = 60;
                        separate-outputs = true;
                    };
                    clock = {
                        format = "{:%a %b %d  %I:%M %p}"; # 12h clock with long date, matching the KDE panel
                        tooltip-format = "<tt><small>{calendar}</small></tt>";
                        calendar.mode = "month";
                    };
                    tray = {
                        icon-size = 18;
                        spacing = 8;
                    };
                    pulseaudio = {
                        format = "{icon} {volume}%";
                        format-muted = "muted";
                        format-icons.default = [
                            "low"
                            "mid"
                            "high"
                        ];
                        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
                    };
                    bluetooth = {
                        format = "BT {status}";
                        on-click = "${pkgs.blueman}/bin/blueman-manager";
                    };
                    network = {
                        format-wifi = "{essid} {signalStrength}%";
                        format-ethernet = "wired";
                        format-disconnected = "offline";
                        on-click = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
                    };
                    backlight = {
                        format = "{percent}%";
                        on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set 5%+";
                        on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
                    };
                    battery = {
                        states = {
                            warning = 30;
                            critical = 15;
                        };
                        format = "{capacity}%";
                        format-charging = "chg {capacity}%";
                        tooltip-format = "{timeTo}";
                    };
                };
                style = ''
                    * {
                        font-family: "Noto Sans", sans-serif;
                        font-size: 12px;
                    }
                    window#waybar {
                        background: rgba(30, 30, 30, 0.85);
                        color: #ffffff;
                        border-radius: 8px;
                    }
                    #workspaces button.active {
                        background: #5ac0c0;
                        color: #1e1e1e;
                        border-radius: 6px;
                    }
                    #battery.critical {
                        color: #ff5555;
                    }
                '';
            };

            home.packages = with pkgs; [
                pavucontrol
                networkmanagerapplet
            ];
        };
}
