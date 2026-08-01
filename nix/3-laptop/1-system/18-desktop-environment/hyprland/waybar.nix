# Waybar
#
# One bar, along the top: weather, clock and the status applets from the right zone of the old Cinnamon panel.
# It floats the way Context's surfaces do - margins off the screen edges, rounded corners, a bordered card -
# so the session reads as windows on a desktop rather than panels bolted to the edges.
#
# There is no bottom bar and no application menu any more. Both were reproductions of Cinnamon panels that
# Context has since replaced outright: its sidebar lists what is running and switches between it, which is
# what the window list was for, and its overview is the application menu. Two ways to do the same thing, one
# of which knew nothing about contexts, is worse than one.
#
# Cinnamon applets with no waybar equivalent are deliberately left out: trilium-api, cinnamon-timer,
# cinnamon-sidebar, the Direct menu and show-hide-applets are all Cinnamon specific and would each need a custom
# module written against their APIs.
#

{ config, pkgs, ... }:
let
    palette = config.technet.theme.palette;
in
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            programs.waybar = {
                enable = true;
                # Run as a systemd user service rather than exec-once. UWSM binds the graphical session to
                # systemd, so the service starts and restarts with the session; the exec-once copy did not
                # come up at all on first login.
                systemd.enable = true;
                settings = {
                    topBar = {
                        layer = "top";
                        position = "top";
                        height = 40;
                        spacing = 8;
                        # Floating, like every Context surface: the margins are the compositor's own gaps,
                        # and they are set here rather than in CSS because a layer surface reserves the space
                        # it is given - a margin in the stylesheet would leave the reserved strip behind.
                        margin-top = 8;
                        margin-left = 8;
                        margin-right = 8;
                        modules-left = [ "custom/weather" ];
                        modules-center = [ "clock" ];
                        modules-right = [
                            "tray"
                            "idle_inhibitor"
                            "backlight"
                            "pulseaudio"
                            "bluetooth"
                            "network"
                            "battery"
                        ];

                        # Replaces the weather@mockturtl applet. The coordinates and the OpenMeteo provider are
                        # taken from that applet's settings, and the units are left to the locale as the applet
                        # had them set to automatic.
                        "custom/weather" = {
                            exec = "${pkgs.hypr-weather}/bin/hypr-weather";
                            interval = 900;
                            return-type = "json";
                            tooltip = true;
                        };

                        # clock-use-24h is false and clock-show-date is true, so a 12 hour clock with the date.
                        # Cinnamon also has clock-show-seconds=true, hence the one second interval.
                        clock = {
                            interval = 1;
                            format = "{:%a %b %e  %I:%M:%S %p}";
                            tooltip-format = "<tt><small>{calendar}</small></tt>";
                            calendar = {
                                mode = "month";
                                format.today = "<b>{}</b>";
                            };
                        };

                        # Replaces the inhibit@cinnamon.org applet
                        idle_inhibitor = {
                            format = "{icon}";
                            format-icons = {
                                activated = "awake";
                                deactivated = "idle";
                            };
                            tooltip-format-activated = "Idle inhibited";
                            tooltip-format-deactivated = "Idle allowed";
                        };

                        tray = {
                            icon-size = 16; # panel-zone-icon-sizes, right zone of panel 1 is 16
                            spacing = 8;
                        };

                        # Cinnamon allows amplified volume up to 150% (desktop/sound maximum-volume)
                        pulseaudio = {
                            format = "{icon} {volume}%";
                            format-muted = "muted";
                            format-icons.default = [
                                "low"
                                "mid"
                                "high"
                            ];
                            max-volume = 150;
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
                };

                # Colours come from the chosen look (technet.theme). The transparent-panels@germanfr
                # extension is set to semi-transparent under Cinnamon, so the panel backgrounds are
                # translucent here too. Translucency uses rgba() with palette.rgb triplets: waybar is
                # GTK3, which rejects 8-digit hex — a bar that fails to parse its CSS exits rather
                # than drawing unstyled, so the whole bar disappears.
                style = ''
                    * {
                        font-family: "Noto Sans", sans-serif;
                        font-size: 12px;
                    }
                    /* The bar as a window among windows: the compositor's rounding plus its border width,
                       and the same 2px border Context draws. The margins are in the config above. */
                    window#waybar {
                        background: rgba(${palette.rgb.surface}, 0.75);
                        color: #${palette.text};
                        border: 2px solid #${palette.border};
                        border-radius: 10px;
                        padding: 4px 8px;
                    }
                    /* Buttons do not inherit the window colour: GTK styles them from the theme, which is
                       Mint-Y-Dark's near black text and left the modules unreadable on the dark bar. Every
                       module that renders as a button therefore sets its own foreground. */
                    #custom-weather,
                    #clock,
                    #pulseaudio,
                    #network,
                    #bluetooth,
                    #battery,
                    #backlight,
                    #tray,
                    #idle_inhibitor {
                        color: #${palette.text};
                        background: transparent;
                        padding: 2px 8px;
                    }
                    #battery.critical {
                        color: #${palette.red};
                    }
                    #idle_inhibitor.activated {
                        color: #${palette.accent};
                    }
                '';
            };

            # The bar comes from the waybar systemd user service enabled above, so nothing is started
            # from exec-once here. Launching it both ways ran two copies of it.

            home.packages = with pkgs; [
                pavucontrol
                networkmanagerapplet
                blueman
            ];
        };
}
