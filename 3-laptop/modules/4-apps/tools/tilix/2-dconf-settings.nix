# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "com/gexperts/Tilix" = {
      close-with-last-session = false;
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
      theme-variant = "light";
      use-tabs = true;
      window-save-state = true;
      window-state = 43908;
      window-style = "normal";
    };

    "com/gexperts/Tilix/profiles/2b7c4080-0ddd-46c5-8f23-563fd3ba789d" = {
      background-color = "#00001B1B2929";
      badge-color = "#AC7EA8";
      badge-color-set = false;
      badge-text = "";
      bold-color-set = false;
      cursor-blink-mode = "system";
      cursor-colors-set = false;
      cursor-shape = "underline";
      default-size-columns = 80;
      font = "Noto Sans Mono 12";
      foreground-color = "#FFFFFFFFFFFF";
      highlight-colors-set = false;
      notify-silence-enabled = true;
      notify-silence-threshold = 60;
      palette = [ "#000000000000" "#FFFF00000000" "#0000ACACFFFF" "#FFFFFFFF0000" "#2B2BC6C63030" "#FFFF0000FFFF" "#0000FFFFFFFF" "#FFFFFFFFFFFF" "#000000000000" "#FFFF00000000" "#0000ACACFFFF" "#FFFFFFFF0000" "#2B2BC6C63030" "#FFFF0000FFFF" "#0000FFFFFFFF" "#FFFFFFFFFFFF" ];
      scrollback-unlimited = true;
      terminal-bell = "icon-sound";
      text-blink-mode = "focused";
      use-system-font = false;
      use-theme-colors = false;
      visible-name = " Default";
    };

  };
}
