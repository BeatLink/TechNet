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
      window-halignment = 1;
      window-height = 52;
      window-losefocus = false;
      window-ontop = false;
      window-refocus = true;
      window-tabbar = true;
      window-valignment = 0;
      window-width = 43;
    };

    "org/guake/keybindings/global" = {
      show-hide = "Calculator";
    };

    "org/guake/style" = {
      cursor-blink-mode = 1;
      cursor-shape = 1;
    };

    "org/guake/style/background" = {
      transparency = 100;
    };

    "org/guake/style/font" = {
      allow-bold = true;
      bold-is-bright = true;
      cell-height-scale = 1.0;
      cell-width-scale = 1.0;
      palette = "#000000000000:#ffff00000000:#0000acacffff:#ffffffff0000:#2c2cc6c63131:#ffff0000ffff:#0000ffffffff:#ffffffffffff:#000000000000:#ffff00000000:#0000acacffff:#ffffffff0000:#2c2cc6c63131:#ffff0000ffff:#0000ffffffff:#ffffffffffff:#ffffffffffff:#00001c3329d0";
      palette-name = "Custom";
    };

  };
}
