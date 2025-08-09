# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "com/gexperts/Tilix" = {
      close-with-last-session = true;
      control-scroll-zoom = true;
      copy-on-select = true;
      enable-wide-handle = false;
      focus-follow-mouse = false;
      new-instance-mode = "new-session";
      paste-advanced-default = true;
      prompt-on-close = true;
      prompt-on-new-session = false;
      quake-height-percent = 25;
      quake-hide-lose-focus = true;
      quake-specific-monitor = 0;
      sidebar-on-right = false;
      tab-position = "top";
      terminal-title-show-when-single = true;
      terminal-title-style = "small";
      theme-variant = "system";
      use-tabs = true;
      window-save-state = true;
      window-state = 43780;
      window-style = "normal";
    };

    "com/gexperts/Tilix/keybindings" = {
      app-new-session = "Calculator";
    };

    "com/gexperts/Tilix/profiles" = {
      list = [ "2b7c4080-0ddd-46c5-8f23-563fd3ba789d" "f2553d7c-01d9-423f-a443-25d23138288e" ];
    };

    "com/gexperts/Tilix/profiles/2b7c4080-0ddd-46c5-8f23-563fd3ba789d" = {
      background-color = "#00001B1B2929";
      background-transparency-percent = 0;
      badge-color = "#AC7EA8";
      badge-color-set = false;
      badge-text = "";
      bold-color-set = false;
      bold-is-bright = true;
      cursor-blink-mode = "system";
      cursor-colors-set = false;
      cursor-shape = "underline";
      default-size-columns = 80;
      dim-transparency-percent = 0;
      font = "Noto Sans Mono 12";
      foreground-color = "#FFFFFFFFFFFF";
      highlight-colors-set = false;
      notify-silence-enabled = true;
      notify-silence-threshold = 30;
      palette = [ "#000000000000" "#FFFF00000000" "#0000ACACFFFF" "#FFFFFFFF0000" "#2B2BC6C63030" "#FFFF0000FFFF" "#0000FFFFFFFF" "#FFFFFFFFFFFF" "#000000000000" "#A5A51D1D2D2D" "#1A1A5F5FB4B4" "#E6E661610000" "#000079790000" "#616135358383" "#000096969191" "#9A9A99999696" ];
      scrollback-unlimited = true;
      terminal-bell = "icon-sound";
      text-blink-mode = "focused";
      use-system-font = false;
      use-theme-colors = false;
      visible-name = "Dark";
    };

    "com/gexperts/Tilix/profiles/f2553d7c-01d9-423f-a443-25d23138288e" = {
      allow-bold = true;
      automatic-switch = [];
      background-color = "#FFFFFFFFFFFF";
      background-transparency-percent = 0;
      backspace-binding = "ascii-delete";
      badge-color = "#AC7EA8";
      badge-color-set = false;
      badge-font = "Monospace 12";
      badge-position = "northeast";
      badge-text = "";
      badge-use-system-font = true;
      bold-color = "#ffffff";
      bold-color-set = false;
      bold-is-bright = true;
      cell-height-scale = 1.0;
      cell-width-scale = 1.0;
      cjk-utf8-ambiguous-width = "narrow";
      cursor-background-color = "#000000";
      cursor-blink-mode = "system";
      cursor-colors-set = false;
      cursor-foreground-color = "#ffffff";
      cursor-shape = "underline";
      custom-command = "";
      custom-hyperlinks = [];
      default-size-columns = 80;
      default-size-rows = 24;
      delete-binding = "delete-sequence";
      dim-transparency-percent = 0;
      draw-margin = 80;
      encoding = "UTF-8";
      exit-action = "close";
      font = "Noto Sans Mono 12";
      foreground-color = "#00001B1B2929";
      highlight-background-color = "#000000";
      highlight-colors-set = false;
      highlight-foreground-color = "#ffffff";
      login-shell = false;
      notify-silence-enabled = true;
      notify-silence-threshold = 30;
      palette = [ "#000000000000" "#FFFF00000000" "#0000ACACFFFF" "#FFFFFFFF0000" "#2B2BC6C63030" "#FFFF0000FFFF" "#0000FFFFFFFF" "#FFFFFFFFFFFF" "#000000000000" "#A5A51D1D2D2D" "#1A1A5F5FB4B4" "#E6E661610000" "#000079790000" "#616135358383" "#000096969191" "#9A9A99999696" ];
      rewrap-on-resize = true;
      scroll-on-keystroke = true;
      scroll-on-output = false;
      scrollback-lines = 8192;
      scrollback-unlimited = true;
      select-by-word-chars = "-,./?%&#:_";
      shortcut = "disabled";
      show-scrollbar = true;
      terminal-bell = "icon-sound";
      text-blink-mode = "focused";
      triggers = [];
      use-custom-command = false;
      use-system-font = false;
      use-theme-colors = false;
      visible-name = "Light";
    };

  };
}
