# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/nemo/preferences" = {
      last-server-connect-method = 0;
      show-hidden-files = true;
    };

    "org/nemo/window-state" = {
      maximized = true;
      sidebar-bookmark-breakpoint = 12;
      sidebar-width = 373;
      start-with-sidebar = true;
    };

  };
}
