# Screen Locking and Idle Management
#
# Mirrors the Cinnamon screensaver and power settings: hypridle drives the timers, hyprlock draws the lock
# screen. hypridle has one set of timers rather than separate AC and battery profiles, so the display and
# lock timeouts use the AC values and the suspend timer checks the power source itself.
#

{ config, ... }:
let
    palette = config.technet.theme.palette;
in
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            programs.hyprlock = {
                enable = true;
                settings = {
                    general = {
                        hide_cursor = true;
                        grace = 0; # Cinnamon requires the password immediately, there is no grace period
                    };
                    background = [
                        {
                            path = "screenshot";
                            blur_passes = 3;
                            blur_size = 8;
                        }
                    ];
                    input-field = [
                        {
                            size = "300, 50";
                            position = "0, -80";
                            halign = "center";
                            valign = "center";
                            outline_thickness = 2;
                            outer_color = "rgb(${palette.accent})"; # The chosen look's accent (technet.theme)
                            inner_color = "rgb(${palette.surface})";
                            font_color = "rgb(${palette.text})";
                            placeholder_text = "Password";
                            fade_on_empty = false;
                        }
                    ];
                    # Cinnamon's screensaver uses a custom time and date format (desktop/screensaver
                    # time-format '%I:%M:%S %p' and date-format ' %A, %B %e %Y') in Noto Sans at 64 and 24.
                    label = [
                        {
                            text = ''cmd[update:1000] date +"%I:%M:%S %p"'';
                            font_size = 64;
                            font_family = "Noto Sans";
                            color = "rgb(${palette.text})";
                            position = "0, 80";
                            halign = "center";
                            valign = "center";
                        }
                        {
                            text = ''cmd[update:60000] date +"%A, %B %e %Y"'';
                            font_size = 24;
                            font_family = "Noto Sans";
                            color = "rgb(${palette.text})";
                            position = "0, 20";
                            halign = "center";
                            valign = "center";
                        }
                    ];
                };
            };

            services.hypridle = {
                enable = true;
                settings = {
                    general = {
                        lock_cmd = "${pkgs.procps}/bin/pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
                        before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session"; # lock-on-suspend
                        after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
                    };
                    listener = [
                        {
                            # Dim shortly before locking. Cinnamon's idle-brightness is 5.
                            timeout = 270;
                            on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 5%";
                            on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
                        }
                        {
                            timeout = 300; # desktop/session idle-delay
                            on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
                        }
                        {
                            timeout = 1800; # sleep-display-ac
                            on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
                            on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
                        }
                        {
                            timeout = 1800; # sleep-inactive-battery-timeout, AC never suspends
                            on-timeout = "${pkgs.hypr-on-mains}/bin/hypr-on-mains || ${pkgs.systemd}/bin/systemctl suspend";
                        }
                    ];
                };
            };
        };
}
