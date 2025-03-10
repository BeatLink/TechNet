# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/nemo/desktop" = {
      font = "Noto Sans Regular 12";
    };

    "org/nemo/plugins" = {
      disabled-actions = [];
    };

    "org/nemo/preferences" = {
      click-double-parent-folder = true;
      default-folder-viewer = "list-view";
      ignore-view-metadata = true;
      inherit-folder-viewer = true;
      last-server-connect-method = 0;
      show-hidden-files = true;
      show-open-in-terminal-toolbar = false;
      tooltips-in-list-view = true;
    };

    "org/nemo/preferences/menu-config" = {
      background-menu-open-in-terminal = false;
      selection-menu-open-in-terminal = false;
    };

    "org/nemo/window-state" = {
      maximized = true;
      sidebar-bookmark-breakpoint = 12;
      sidebar-width = 373;
      start-with-sidebar = true;
    };

  };
}
