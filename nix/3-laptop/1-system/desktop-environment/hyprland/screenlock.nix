# Screen Locking and Idle Management
#
# Mirrors the KDE kscreenlocker settings: lock after 2 minutes of inactivity, password required, and no locking
# on resume or startup. hypridle drives the timers and hyprlock draws the lock screen.
#

{ pkgs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            programs.hyprlock = {
                enable = true;
                settings = {
                    general = {
                        hide_cursor = true;
                        grace = 1; # Matches passwordRequiredDelay from the KDE config
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
                            outer_color = "rgb(5ac0c0)";
                            inner_color = "rgb(1e1e1e)";
                            font_color = "rgb(ffffff)";
                            placeholder_text = "Password";
                            fade_on_empty = false;
                        }
                    ];
                    label = [
                        {
                            text = "$TIME";
                            font_size = 64;
                            color = "rgb(ffffff)";
                            position = "0, 80";
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
                        before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
                        after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
                    };
                    listener = [
                        {
                            timeout = 110; # Dim just before locking
                            on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 20%";
                            on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
                        }
                        {
                            timeout = 120; # 2 minutes, matching the KDE autoLock timeout
                            on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
                        }
                        {
                            timeout = 300;
                            on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
                            on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
                        }
                    ];
                };
            };
        };
}
