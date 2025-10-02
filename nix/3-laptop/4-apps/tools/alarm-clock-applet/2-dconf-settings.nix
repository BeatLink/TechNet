# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "io/github/alarm-clock-applet" = {
      alarms = [ (mkUint32 0) 4 1 ];
      gconf-migrated = true;
      show-label = true;
    };

    "io/github/alarm-clock-applet/alarm-0" = {
      active = true;
      command = "rhythmbox-client --play";
      message = "Wind Down";
      notify-type = "sound";
      repeat = [ "sun" "mon" "tue" "wed" "thu" "fri" "sat" ];
      sound-file = "file:///Storage/Files/Sounds/Interface%20Sounds/Amazon/Amazon%20Fire%20Phone%20Startup%20(Extracted%20with%20Boot%20Animation).m4a";
      sound-repeat = false;
      time = mkInt64 77400;
      timestamp = mkInt64 1759458600;
      type = "clock";
    };

    "io/github/alarm-clock-applet/alarm-1" = {
      active = true;
      command = "sox";
      message = "Wake Up";
      repeat = [ "sun" "mon" "tue" "wed" "thu" "fri" "sat" ];
      sound-file = "file:///Storage/Files/Sounds/Interface%20Sounds/Amazon/Amazon%20Fire%20Phone%20Startup%20(Extracted%20with%20Boot%20Animation).m4a";
      sound-repeat = false;
      time = mkInt64 18000;
      timestamp = mkInt64 1759485600;
      type = "clock";
    };

    "io/github/alarm-clock-applet/alarm-4" = {
      active = true;
      command = "sox";
      message = "Sleep";
      repeat = [ "sun" "mon" "tue" "wed" "thu" "fri" "sat" ];
      sound-file = "file:///Storage/Files/Sounds/Interface%20Sounds/Amazon/Amazon%20Fire%20Phone%20Startup%20(Extracted%20with%20Boot%20Animation).m4a";
      sound-repeat = false;
      time = mkInt64 78900;
      timestamp = mkInt64 1759460100;
      type = "clock";
    };

  };
}
