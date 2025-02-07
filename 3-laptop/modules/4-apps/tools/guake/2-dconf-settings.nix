# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/guake/general" = {
      compat-delete = "delete-sequence";
      display-n = 0;
      display-tab-names = 0;
      gtk-use-system-default-theme = true;
      hide-tabs-if-one-tab = false;
      history-size = 1000;
      infinite-history = true;
      load-guake-yml = true;
      max-tab-name-length = 100;
      mouse-display = true;
      new-tab-after = true;
      open-tab-cwd = true;
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
      start-at-login = true;
      start-fullscreen = true;
      tab-close-buttons = true;
      tab-ontop = true;
      use-audible-bell = true;
      use-default-font = true;
      use-popup = true;
      use-scrollbar = true;
      use-trayicon = true;
      window-halignment = 0;
      window-height = 50;
      window-losefocus = true;
      window-refocus = true;
      window-tabbar = true;
      window-valignment = 0;
      window-width = 100;
    };

    "org/guake/style/background" = {
      transparency = 90;
    };

    "org/guake/style/font" = {
      allow-bold = true;
      bold-is-bright = true;
      palette = "#000000000000:#cdcb00000000:#0000cdcb0000:#cdcbcdcb0000:#1e1a908fffff:#cdcb0000cdcb:#0000cdcbcdcb:#e5e2e5e2e5e2:#4ccc4ccc4ccc:#ffff00000000:#0000ffff0000:#ffffffff0000:#46458281b4ae:#ffff0000ffff:#0000ffffffff:#ffffffffffff:#ffffffffffff:#000000000000";
      palette-name = "Xterm";
    };

  };
}
