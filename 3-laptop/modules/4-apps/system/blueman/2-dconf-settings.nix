{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/blueman/general" = {
      plugin-list = [ "NetUsage" ];
      window-properties = [ 1920 1008 0 72 ];
    };

    "org/blueman/plugins/autoconnect" = {
      services = [
        (mkTuple [ "83:BA:4A:3E:E1:42" "00000000-0000-0000-0000-000000000000" ])
        (mkTuple [ "41:42:DC:6D:EB:20" "00000000-0000-0000-0000-000000000000" ])
      ];
    };

    "org/blueman/plugins/recentconns" = {
      max-items = 10;

      recent-connections = [
        [
          (mkDictionaryEntry {
            "adapter" = "30:03:C8:00:01:7A";
            "address" = "83:BA:4A:3E:E1:42";
            "alias" = "KTE-007";
            "icon" = "audio-headset";
            "name" = "Audio and input profiles";
            "uuid" = "00000000-0000-0000-0000-000000000000";
            "time" = "1753930258.915562";
          })
        ]
      ];
    };

    "org/blueman/plugins/standarditems" = {
      toggle-manager-onclick = true;
    };
  };
}
