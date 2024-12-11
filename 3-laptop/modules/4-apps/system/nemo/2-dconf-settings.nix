# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/nemo/plank/preferences" = {
      show-hidden-files = true;
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
