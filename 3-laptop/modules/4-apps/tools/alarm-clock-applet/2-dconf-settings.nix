# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "io/github/alarm-clock-applet" = {
      alarms = [ (mkUint32 0) 1 2 3 ];
      gconf-migrated = true;
      show-label = true;
    };

    "io/github/alarm-clock-applet/alarm-0" = {
      active = true;
      command = "rhythmbox-client --play";
      message = "Go to Bed";
      notify-type = "sound";
      repeat = [ "sun" "mon" "tue" "wed" "thu" "fri" "sat" ];
      sound-file = "file:///media/beatlink/Storage/Files/Music/60/Soundtracks/Jack%20Wall%20-%20Vigil.ogg";
      sound-repeat = true;
      time = mkInt64 81900;
      timestamp = mkInt64 1738986300;
      type = "clock";
    };

    "io/github/alarm-clock-applet/alarm-1" = {
      active = true;
      command = "/media/beatlink/Storage/Apps/Tools/brightness-scripts/brightness-min.sh";
      message = "Brightness Min";
      notify-type = "command";
      repeat = [ "sun" "mon" "tue" "wed" "thu" "fri" "sat" ];
      sound-file = "file:///usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga";
      sound-repeat = true;
      time = mkInt64 79200;
      timestamp = mkInt64 1738983600;
      type = "clock";
    };

    "io/github/alarm-clock-applet/alarm-2" = {
      active = true;
      command = "/media/beatlink/Storage/Apps/Tools/brightness-scripts/brightness-half.sh";
      message = "Brightness Half";
      notify-type = "command";
      repeat = [ "sun" "mon" "tue" "wed" "thu" "fri" "sat" ];
      sound-file = "file:///usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga";
      sound-repeat = true;
      time = mkInt64 64800;
      timestamp = mkInt64 1738969200;
      type = "clock";
    };

    "io/github/alarm-clock-applet/alarm-3" = {
      active = true;
      command = "/media/beatlink/Storage/Apps/Tools/brightness-scripts/brightness-max.sh";
      message = "Brightness Max";
      notify-type = "command";
      repeat = [ "sun" "mon" "tue" "wed" "thu" "fri" "sat" ];
      sound-file = "file:///usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga";
      sound-repeat = true;
      time = mkInt64 21600;
      timestamp = mkInt64 1739012400;
      type = "clock";
    };

  };
}
