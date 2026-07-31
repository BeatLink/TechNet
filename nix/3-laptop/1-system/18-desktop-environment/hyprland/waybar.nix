# Waybar
#
# Waybar replaces the Cinnamon panels. Cinnamon runs two panels (org/cinnamon panels-enabled), both 48px tall
# (panels-height), and this reproduces both:
#
#   Top    - always visible (panels-autohide '1:false'), carrying the menu, weather, clock, timer and the status
#            applets from the right zone of the Cinnamon panel
#   Bottom - auto hiding (panels-autohide '2:intel'), carrying the window list. Cinnamon's 'intel' mode hides the
#            panel only when a window would overlap it, which waybar cannot express, so it uses ordinary
#            autohide: the bar reveals when the pointer reaches the bottom edge.
#
# Cinnamon applets with no waybar equivalent are deliberately left out for now: trilium-api, cinnamon-timer,
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
                    # Top panel, mirroring panel1 from the Cinnamon config
                    topBar = {
                        layer = "top";
                        position = "top";
                        height = 48; # panels-height '1:48'
                        spacing = 8;
                        modules-left = [
                            "custom/menu"
                            "custom/weather"
                        ];
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

                        # Stands in for the Cinnamon menu applet, opening the rofi launcher
                        "custom/menu" = {
                            format = "Apps";
                            on-click =
                                "${pkgs.nwg-menu}/bin/nwg-menu -wm hyprland -va bottom -ha left -k -d "
                                + "-term ${pkgs.tilix}/bin/tilix -fm ${pkgs.nemo}/bin/nemo "
                                + "-cmd-lock '${pkgs.hyprlock}/bin/hyprlock' -cmd-logout 'hyprctl dispatch exit'";
                            tooltip = false;
                        };

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

                    # Bottom panel, mirroring panel2 from the Cinnamon config. This carries the
                    # grouped-window-list applet, so wlr/taskbar is used rather than hyprland/workspaces.
                    bottomBar = {
                        layer = "top";
                        position = "bottom";
                        height = 48; # panels-height '2:48'
                        spacing = 8;
                        # Cinnamon's panels-autohide is '2:intel', ie intelligent hide: the panel stays visible
                        # and only gets out of the way when a window would overlap it. Waybar's `hide` is
                        # unconditional auto-hide, which is the '2:true' behaviour instead, so `dock` mode is
                        # used to keep the taskbar visible and reserve its space.
                        mode = "dock";
                        modules-left = [ "hyprland/workspaces" ];
                        modules-center = [ "wlr/taskbar" ];
                        modules-right = [ "hyprland/submap" ];

                        "hyprland/workspaces" = {
                            format = "{id}";
                            on-click = "activate";
                        };

                        # Cinnamon's grouped-window-list groups windows of the same application and shows icons at
                        # 32px in the left zone of panel 2 (panel-zone-icon-sizes)
                        "wlr/taskbar" = {
                            format = "{icon} {title}";
                            icon-size = 32;
                            tooltip-format = "{title}";
                            on-click = "activate";
                            on-click-middle = "close";
                            markup = false;
                        };
                    };
                };

                # Colours come from the chosen look (technet.theme). The transparent-panels@germanfr
                # extension is set to semi-transparent under Cinnamon, so the panel backgrounds are
                # translucent here too — the surface colour with an alpha suffix.
                style = ''
                    * {
                        font-family: "Noto Sans", sans-serif;
                        font-size: 12px;
                    }
                    window#waybar {
                        background: #${palette.surface}c0;
                        color: #${palette.text};
                    }
                    /* Buttons do not inherit the window colour: GTK styles them from the theme, which is
                       Mint-Y-Dark's near black text and left the taskbar unreadable on the dark bar. Every
                       module that renders as a button therefore sets its own foreground. */
                    #taskbar button,
                    #workspaces button,
                    #custom-menu,
                    #custom-weather,
                    #clock,
                    #pulseaudio,
                    #network,
                    #bluetooth,
                    #battery,
                    #backlight,
                    #tray,
                    #idle_inhibitor,
                    #submap {
                        color: #${palette.text};
                        background: transparent;
                    }
                    #taskbar button.active {
                        border-bottom: 2px solid #${palette.accent};
                        background: #${palette.accent}26;
                    }
                    #workspaces button.active {
                        background: #${palette.accent};
                        color: #${palette.surface};
                        border-radius: 6px;
                    }
                    #battery.critical {
                        color: #${palette.red};
                    }
                    #idle_inhibitor.activated {
                        color: #${palette.accent};
                    }
                '';
            };

            # Both bars come from the single waybar systemd user service enabled above, so nothing is
            # started from exec-once here. Launching it both ways ran two copies of every bar.

            home.packages = with pkgs; [
                pavucontrol
                networkmanagerapplet
                blueman
            ];
        };
}
