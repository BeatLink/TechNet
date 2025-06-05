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
      services = [ (mkTuple [ "41:42:DC:6D:EB:20" "00000000-0000-0000-0000-000000000000" ]) ];
    };

    "org/blueman/plugins/recentconns" = {
      max-items = 10;
      recent-connections = [ {
        adapter = "30:03:C8:00:01:7A";
        address = "41:42:DC:6D:EB:20";
        alias = "KTE-006";
        icon = "audio-headphones";
        name = "Audio and input profiles";
        uuid = "00000000-0000-0000-0000-000000000000";
        time = "1736203641.3961515";
      } ];
    };

    "org/blueman/plugins/standarditems" = {
      toggle-manager-onclick = true;
    };

  };
}
