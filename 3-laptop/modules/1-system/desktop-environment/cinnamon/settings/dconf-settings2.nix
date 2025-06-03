# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/cinnamon" = {
      alttab-switcher-delay = 100;
      alttab-switcher-style = "icons+preview";
      device-aliases = [ "/org/freedesktop/UPower/devices/battery_BAT1:=Internal Battery" "/org/freedesktop/UPower/devices/keyboard_hidpp_battery_0:= Wireless Keyboard" ];

      enabled-desklets = [];
      enabled-extensions = [ "transparent-panels@germanfr" ];
      hotcorner-layout = [ "expo:false:0" "desktop:true:100" "expo:true:100" "scale:true:100" ];
      lock-desklets = false;
      looking-glass-history = [ "glass.log" "global.segfault()" ];

      no-adjacent-panel-barriers = true;
      panel-edit-mode = false;
      panel-launchers = [ "DEPRECATED" ];
      panel-zone-icon-sizes = "[{\"panelId\":1,\"left\":16,\"center\":16,\"right\":16}]";
      panel-zone-symbolic-icon-sizes = "[{\"panelId\": 1, \"left\": 16, \"center\": 16, \"right\": 16}]";
      panel-zone-text-sizes = "[{\"panelId\":1,\"left\":10,\"center\":10,\"right\":10}]";
      panels-autohide = [ "1:false" "2:intel" ];
      panels-enabled = [ "1:0:top" ];
      panels-height = [ "1:40" "2:60" ];
      panels-hide-delay = [ "1:0" "2:0" ];
      panels-show-delay = [ "1:0" "2:0" ];
      show-media-keys-osd = "small";
      workspace-expo-view-as-grid = true;
      workspace-osd-visible = true;
    };

    "org/cinnamon/cinnamon-session" = {
      quit-delay-toggle = true;
      quit-time-delay = 5;
    };




    "org/cinnamon/desktop/a11y/mouse" = {
      dwell-click-enabled = false;
      dwell-threshold = 10;
      dwell-time = 1.2;
      secondary-click-enabled = false;
      secondary-click-time = 1.2;
    };

    "org/cinnamon/desktop/applications/calculator" = {
      exec = "gnome-calculator";
    };

    "org/cinnamon/desktop/applications/terminal" = {
      exec = "tilix";
      exec-arg = "";
    };





    "org/cinnamon/desktop/interface" = {
      clock-show-date = true;
      clock-show-seconds = true;
      clock-use-24h = false;
      cursor-blink-time = 1200;
      cursor-size = 24;
      cursor-theme = "Bibata-Modern-Classic";
      first-day-of-week = 0;
      font-name = "Noto Sans 12";
      gtk-overlay-scrollbars = true;

      scaling-factor = mkUint32 0;
      text-scaling-factor = 1.0;
      toolkit-accessibility = true;
    };

    "org/cinnamon/desktop/keybindings" = {
      looking-glass-keybinding = [];
    };

    "org/cinnamon/desktop/keybindings/media-keys" = {
      calculator = [];
      home = [ "<Super>e" "XF86Explorer" "HomePage" ];
      next = [ "AudioNext" ];
      pause = [];
      play = [ "AudioPlay" ];
      screensaver = [ "<Control><Alt>l" "XF86ScreenSaver" "<Super>l" ];
      terminal = [ "<Primary><Alt>t" "Calculator" ];
    };

    "org/cinnamon/desktop/media-handling" = {
      autorun-never = false;
    };

    "org/cinnamon/desktop/notifications" = {
      display-notifications = true;
      notification-duration = 5;
      remove-old = true;
    };

    "org/cinnamon/desktop/peripherals/keyboard" = {
      delay = mkUint32 500;
      numlock-state = true;
      repeat = true;
      repeat-interval = mkUint32 19;
    };

    "org/cinnamon/desktop/peripherals/mouse" = {
      double-click = 400;
      drag-threshold = 8;
      speed = 0.0;
    };

    "org/cinnamon/desktop/peripherals/touchpad" = {
      click-method = "default";
      disable-while-typing = true;
      send-events = "enabled";
      speed = 0.0;
      tap-to-click = true;
    };

    "org/cinnamon/desktop/screensaver" = {
      allow-media-control = false;
      lock-enabled = true;
      show-album-art = false;
    };

    "org/cinnamon/desktop/session" = {
      idle-delay = mkUint32 1800;
    };

    "org/cinnamon/desktop/wm/preferences" = {
      action-scroll-titlebar = "none";
      audible-bell = false;
      button-layout = ":minimize,maximize,close";
      focus-mode = "click";
      focus-new-windows = "smart";
      min-window-opacity = 30;
      num-workspaces = 1;
      titlebar-font = "Noto Sans 12";
      visual-bell = false;
      workspace-names = [];
    };

    "org/cinnamon/gestures" = {
      enabled = true;
      pinch-in-2 = "";
      pinch-percent-threshold = mkUint32 40;
      swipe-down-2 = "PUSH_TILE_DOWN::end";
      swipe-down-3 = "MINIMIZE::end";
      swipe-down-4 = "PUSH_TILE_DOWN::end";
      swipe-left-2 = "PUSH_TILE_LEFT::end";
      swipe-left-3 = "EXEC:: xdotool key alt+Tab::end";
      swipe-left-4 = "PUSH_TILE_LEFT::end";
      swipe-percent-threshold = mkUint32 40;
      swipe-right-2 = "PUSH_TILE_RIGHT::end";
      swipe-right-3 = "";
      swipe-right-4 = "PUSH_TILE_RIGHT::end";
      swipe-up-2 = "PUSH_TILE_UP::end";
      swipe-up-3 = "MINIMIZE::end";
      swipe-up-4 = "PUSH_TILE_UP::end";
      tap-3 = "MEDIA_PLAY_PAUSE::end";
    };

    "org/cinnamon/launcher" = {
      check-frequency = 60;
      memory-limit = 1024;
    };

    "org/cinnamon/muffin" = {
      attach-modal-dialogs = true;
      bring-windows-to-current-workspace = true;
      draggable-border-width = 10;
      experimental-features = [];
      placement-mode = "automatic";
      resize-threshold = 24;
      tile-maximize = true;
      unredirect-fullscreen-windows = true;
      workspace-cycle = true;
      workspaces-only-on-primary = false;
    };

    "org/cinnamon/settings-daemon/peripherals/keyboard" = {
      numlock-state = "on";
    };

    "org/cinnamon/settings-daemon/peripherals/touchpad" = {
      horizontal-scrolling = true;
    };

    "org/cinnamon/settings-daemon/peripherals/touchscreen" = {
      orientation-lock = true;
    };


    "org/cinnamon/settings-daemon/plugins/xsettings" = {
      buttons-have-icons = true;
      menus-have-icons = true;
    };


  };

}
