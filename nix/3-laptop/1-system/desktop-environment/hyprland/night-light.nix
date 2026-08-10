# Night Light
#
# Cinnamon's night light is provided by cinnamon-settings-daemon and configured under
# settings-daemon/plugins/color. Hyprland has no settings daemon, so hyprsunset provides the same colour
# temperature shift.
#
# The Cinnamon configuration being reproduced:
#   night-light-enabled       true
#   night-light-temperature   2700
#   night-light-schedule-mode manual
#   night-light-schedule-from 21.0    (21:00)
#   night-light-schedule-to   6       (06:00)
#
# hyprsunset applies the profile whose time has most recently passed, so the two entries below hold 2700K
# through the night and return to an unmodified screen at 06:00. This also means a session started mid window
# picks up the correct temperature rather than waiting for the next boundary.
#

{ ... }:
{
    home-manager.users.beatlink =
        { ... }:
        {
            services.hyprsunset = {
                enable = true;
                settings = {
                    profile = [
                        {
                            time = "6:00"; # night-light-schedule-to
                            identity = true; # No shift during the day
                        }
                        {
                            time = "21:00"; # night-light-schedule-from
                            temperature = 2700; # night-light-temperature
                        }
                    ];
                };
            };
        };
}
