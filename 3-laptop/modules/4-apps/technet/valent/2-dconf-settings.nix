# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "ca/andyholmes/valent" = {
      name = "Odin";
    };

    "ca/andyholmes/valent/device/eec8ec68_56b6_492f_904b_838330bcaa45" = {
      paired = true;
    };

    "ca/andyholmes/valent/device/eec8ec68_56b6_492f_904b_838330bcaa45/plugin/battery" = {
      full-notification = true;
    };

    "ca/andyholmes/valent/device/eec8ec68_56b6_492f_904b_838330bcaa45/plugin/clipboard" = {
      auto-pull = true;
      auto-push = true;
    };

    "ca/andyholmes/valent/device/eec8ec68_56b6_492f_904b_838330bcaa45/plugin/connectivity_report" = {
      offline-notification = true;
    };

    "ca/andyholmes/valent/device/eec8ec68_56b6_492f_904b_838330bcaa45/plugin/contacts" = {
      local-sync = true;
    };

    "ca/andyholmes/valent/device/eec8ec68_56b6_492f_904b_838330bcaa45/plugin/sftp" = {
      auto-mount = true;
      local-allow = true;
    };


    "ca/andyholmes/valent/device/eec8ec68_56b6_492f_904b_838330bcaa45/plugin/share" = {
      download-folder = "/Storage/Files/Downloads";
    };

  };
}
