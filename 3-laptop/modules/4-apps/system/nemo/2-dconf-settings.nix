# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/nemo/plank/plank/preferences" = {
      show-hidden-files = true;
    };

    "org/nemo/plank/plank/search" = {
      search-reverse-sort = false;
      search-sort-column = "name";
    };

    "org/nemo/plank/plank/window-state" = {
      maximized = true;
      sidebar-bookmark-breakpoint = 0;
      start-with-sidebar = true;
    };

    "org/nemo/plank/preferences" = {
      close-device-view-on-device-eject = true;
      quick-renames-with-pause-in-between = true;
      show-computer-icon-toolbar = true;
      show-hidden-files = true;
      show-home-icon-toolbar = true;
      show-new-folder-icon-toolbar = true;
      show-open-in-terminal-toolbar = true;
      show-reload-icon-toolbar = true;
      show-show-thumbnails-toolbar = true;
    };

    "org/nemo/plank/preferences/menu-config" = {
      selection-menu-copy-to = true;
      selection-menu-duplicate = true;
      selection-menu-make-link = true;
      selection-menu-move-to = true;
    };

    "org/nemo/plank/search" = {
      search-reverse-sort = false;
      search-sort-column = "name";
    };

    "org/nemo/plank/window-state" = {
      maximized = true;
      sidebar-bookmark-breakpoint = 0;
      start-with-sidebar = true;
    };

  };
}
