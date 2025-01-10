# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/blueman/general" = {
      plugin-list = [ "NetUsage" ];
      window-properties = [ 1920 1008 0 72 ];
    };

    "org/blueman/plugins/autoconnect" = {
      services = [ (mkTuple [ "/org/bluez/hci0/dev_41_42_DC_6D_EB_20" "00000000-0000-0000-0000-000000000000" ]) ];
    };

    "org/blueman/plugins/recentconns" = {
      max-items = 10;
      recent-connections = [[
        (mkDictionaryEntry ["adapter" "30:03:C8:00:01:7A"])
        (mkDictionaryEntry ["address" "41:42:DC:6D:EB:20"])
        (mkDictionaryEntry ["alias" "KTE-006"])
        (mkDictionaryEntry ["icon" "audio-headphones"])
        (mkDictionaryEntry ["name" "Audio and input profiles"])
        (mkDictionaryEntry ["uuid" "00000000-0000-0000-0000-000000000000"])
        (mkDictionaryEntry ["time" "1736203641.3961515"])
      ]];
    };

    "org/blueman/plugins/standarditems" = {
      toggle-manager-onclick = true;
    };

  };
}
