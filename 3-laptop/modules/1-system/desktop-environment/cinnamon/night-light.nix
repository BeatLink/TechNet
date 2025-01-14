{ lib, ... }:

with lib.hm.gvariant;

{
    dconf.settings = {
        "org/cinnamon/settings-daemon/plugins/color" = {
            "night-light-enabled" = true;
            "night-light-schedule-from" = 21.75;
            "night-light-schedule-mode" =  "manual";
            "night-light-schedule-to" =  6;
            "night-light-temperature" =  2700;
        };
    };
}