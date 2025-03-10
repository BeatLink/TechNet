# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/guake/general" = {
      compat-delete = "delete-sequence";
      display-n = 0;
      display-tab-names = 0;
      fullscreen-hide-tabbar = false;
      gtk-use-system-default-theme = true;
      hide-tabs-if-one-tab = false;
      history-size = 1000;
      infinite-history = true;
      lazy-losefocus = false;
      load-guake-yml = true;
      max-tab-name-length = 100;
      mouse-display = true;
      new-tab-after = true;
      open-tab-cwd = true;
      prompt-on-close-tab = 1;
      prompt-on-quit = true;
      quick-open-command-line = "xed %(file_path)s";
      quick-open-enable = true;
      restore-tabs-notify = true;
      restore-tabs-startup = true;
      save-tabs-when-changed = true;
      schema-version = "3.10";
      scroll-keystroke = true;
      scroll-output = true;
      search-engine = 1;
      set-window-title = true;
      start-at-login = false;
      start-fullscreen = false;
      tab-close-buttons = true;
      tab-ontop = true;
      use-audible-bell = true;
      use-default-font = true;
      use-popup = false;
      use-scrollbar = true;
      use-trayicon = true;
      window-halignment = 0;
      window-height = 100;
      window-losefocus = false;
      window-ontop = false;
      window-refocus = true;
      window-tabbar = true;
      window-valignment = 0;
      window-width = 100;
    };

    "org/guake/keybindings/global" = {
      show-hide = "Calculator";
    };

    "org/guake/style" = {
      cursor-shape = 1;
    };

    "org/guake/style/background" = {
      transparency = 100;
    };

    "org/guake/style/font" = {
      allow-bold = true;
      bold-is-bright = true;
      cell-height-scale = 1.0;
      palette = "#000000000000:#ffff00000000:#00008887ffff:#ffff78780000:#8f8ff0f0a4a4:#52523c3c7979:#dcdc8a8adddd:#d9d9d9d9d9d9:#010128284949:#ffff84438443:#0000acacffff:#ffffbebe6f6f:#3333d1d17a7a:#68685555dede:#c0c06161cbcb:#f1f1f1f1f1f1:#000000000000:#ffffffffffff";
      palette-name = "Custom";
    };

  };
}
