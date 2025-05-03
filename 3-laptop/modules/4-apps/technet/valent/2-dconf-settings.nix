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

    "ca/andyholmes/valent/device/eec8ec68_56b6_492f_904b_838330bcaa45/plugin/runcommand" = {
      commands = "{'24da1a0e-920b-4ea2-b166-577bc0a3c307': {'name': 'Shutdown', 'command': 'sudo systemctl poweroff'}, 'e5e5b2a9-9264-42e1-8aee-9ad9773f0802': {'name': 'Sleep', 'command': 'systemctl suspend'}, '07f552db-09e6-4271-bf7c-a6a424e2e231': {'name': 'Lock Screen', 'command': 'cinnamon-screensaver-command -l'}, '31f2fd45-4939-452b-8b87-61a06d0e1fcf': {'name': 'Unlock Screen', 'command': 'cinnamon-screensaver-command -d'}}";
    };

    "ca/andyholmes/valent/device/eec8ec68_56b6_492f_904b_838330bcaa45/plugin/share" = {
      download-folder = "/Storage/Files/Downloads";
    };

  };
}
