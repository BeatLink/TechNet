# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/desktop/a11y/applications" = {
      screen-keyboard-enabled = false;
      screen-reader-enabled = false;
    };

    "org/gnome/desktop/a11y/mouse" = {
      dwell-click-enabled = false;
      dwell-threshold = 10;
      dwell-time = 1.2;
      secondary-click-enabled = false;
      secondary-click-time = 1.2;
    };

    "org/gnome/desktop/interface" = {
      clock-format = "12h";
      clock-show-date = true;
      clock-show-seconds = true;
      cursor-blink = true;
      cursor-blink-time = 1200;
      cursor-blink-timeout = 10;
      cursor-size = 24;
      cursor-theme = "Bibata-Modern-Classic";
      document-font-name = "Noto Sans 12";
      enable-animations = true;
      font-name = "Noto Sans 12";
      gtk-color-palette = "black:white:gray50:red:purple:blue:light blue:green:yellow:orange:lavender:brown:goldenrod4:dodger blue:pink:light green:gray10:gray30:gray75:gray90";
      gtk-color-scheme = "";
      gtk-enable-primary-paste = true;
      gtk-im-module = "";
      gtk-im-preedit-style = "callback";
      gtk-im-status-style = "callback";
      gtk-key-theme = "Default";
      gtk-theme = "Mint-Y-Aqua";
      gtk-timeout-initial = 200;
      gtk-timeout-repeat = 20;
      icon-theme = "Mint-Y-Aqua";
      menubar-accel = "F10";
      menubar-detachable = false;
      menus-have-tearoff = false;
      monospace-font-name = "Noto Sans Mono 12";
      scaling-factor = mkUint32 0;
      text-scaling-factor = 1.0;
      toolbar-detachable = false;
      toolbar-icons-size = "large";
      toolbar-style = "both-horiz";
      toolkit-accessibility = false;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "default";
      double-click = 400;
      drag-threshold = 8;
      left-handed = false;
      middle-click-emulation = false;
      natural-scroll = false;
      speed = 0.0;
    };

    "org/gnome/desktop/privacy" = {
      recent-files-max-age = 7;
    };

    "org/gnome/desktop/sound" = {
      event-sounds = false;
      input-feedback-sounds = false;
      theme-name = "LinuxMint";
    };

    "org/gnome/desktop/wm/preferences" = {
      action-double-click-titlebar = "toggle-maximize";
      audible-bell = false;
      button-layout = ":minimize,maximize,close";
      focus-mode = "click";
      focus-new-windows = "smart";
      mouse-button-modifier = "<Alt>";
      num-workspaces = 4;
      theme = "Mint-Y";
      visual-bell = false;
      visual-bell-type = "fullscreen-flash";
      workspace-names = [];
    };

  };
}
