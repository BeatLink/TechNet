# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/cinnamon" = {
      alttab-switcher-delay = 100;
      alttab-switcher-style = "icons+preview";
      desktop-effects-maximize = true;
      device-aliases = [ "/org/freedesktop/UPower/devices/battery_BAT1:=Internal Battery" "/org/freedesktop/UPower/devices/keyboard_hidpp_battery_0:= Wireless Keyboard" ];
      enabled-applets = [ "panel1:right:3:xapp-status@cinnamon.org:4" "panel1:right:9:notifications@cinnamon.org:5" "panel1:right:11:network@cinnamon.org:10" "panel1:right:10:sound@cinnamon.org:11" "panel1:right:14:power@cinnamon.org:12" "panel1:center:0:calendar@cinnamon.org:120" "panel1:right:5:printers@cinnamon.org:134" "panel1:right:8:show-hide-applets@mohammad-sn:142" "panel1:right:4:systray@cinnamon.org:143" "panel1:right:6:gpaste-reloaded@feuerfuchs.eu:144" "panel1:center:2:paneldo@beatlink:145" "panel1:right:7:power-profiles@rcalixte:147" "panel1:right:12:qredshift@quintao:148" "panel1:center:1:cinnamon-timer@jake1164:149" "panel1:left:1:places-bookmarks@dmo60.de:154" "panel1:right:13:inhibit@cinnamon.org:156" "panel1:right:1:panel-launchers@cinnamon.org:168" "panel1:left:0:menu@cinnamon.org:172" ];
      enabled-desklets = [];
      enabled-extensions = [ "user-shadows@nathan818fr" "transparent-panels@germanfr" ];
      hotcorner-layout = [ "expo:false:0" "desktop:true:100" "expo:true:100" "scale:true:100" ];
      lock-desklets = false;
      looking-glass-history = [ "glass.log" "global.segfault()" ];
      next-applet-id = 173;
      next-desklet-id = 9;
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
      window-effect-speed = 0;
      workspace-expo-view-as-grid = true;
      workspace-osd-visible = true;
    };

    "org/cinnamon/cinnamon-session" = {
      quit-delay-toggle = true;
      quit-time-delay = 5;
    };

    "org/cinnamon/desktop/a11y/applications" = {
      screen-keyboard-enabled = true;
      screen-magnifier-enabled = false;
      screen-reader-enabled = false;
    };

    "org/cinnamon/desktop/a11y/keyboard" = {
      bouncekeys-beep-reject = true;
      bouncekeys-delay = 140;
      bouncekeys-enable = false;
      disable-timeout = 120;
      enable = false;
      feature-state-change-beep = false;
      mousekeys-accel-time = 1200;
      mousekeys-enable = false;
      mousekeys-init-delay = 160;
      mousekeys-max-speed = 500;
      slowkeys-beep-accept = true;
      slowkeys-beep-press = true;
      slowkeys-beep-reject = false;
      slowkeys-delay = 300;
      slowkeys-enable = false;
      stickykeys-enable = false;
      stickykeys-modifier-beep = true;
      stickykeys-two-key-off = true;
      timeout-enable = false;
      togglekeys-enable-beep = true;
      togglekeys-enable-osd = true;
      togglekeys-sound-on = "/usr/share/cinnamon/sounds/togglekeys-sound-on.ogg";
    };

    "org/cinnamon/desktop/a11y/magnifier" = {
      mag-factor = 1.0;
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
      exec = "gnome-terminal";
      exec-arg = "--";
    };

    "org/cinnamon/desktop/background" = {
      picture-options = "zoom";
      picture-uri = "file:///home/beatlink/.config/variety/wallpaper/wallpaper-quote-cb20c22f2883bb728c47935b0bb5519a.jpg";
    };

    "org/cinnamon/desktop/background/slideshow" = {
      delay = 15;
      image-source = "xml:///usr/share/cinnamon-background-properties/linuxmint-una.xml";
      slideshow-enabled = false;
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
      gtk-theme = "Mint-Y-Deep-Sky";
      gtk-theme-backup = "Mint-Y-Aqua";
      icon-theme = "Mint-Y-Aqua";
      icon-theme-backup = "Mint-Y-Aqua";
      scaling-factor = mkUint32 0;
      text-scaling-factor = 1.0;
      toolkit-accessibility = true;
    };

    "org/cinnamon/desktop/keybindings" = {
      looking-glass-keybinding = [];
    };

    "org/cinnamon/desktop/keybindings/media-keys" = {
      next = [ "AudioNext" ];
      pause = [];
      play = [ "AudioPlay" ];
      screensaver = [ "<Control><Alt>l" "XF86ScreenSaver" "<Super>l" ];
      terminal = [ "<Primary><Alt>t" ];
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

    "org/cinnamon/desktop/sound" = {
      event-sounds = false;
      maximum-volume = 150;
      volume-sound-file = "/usr/share/mint-artwork/sounds/volume.oga";
    };

    "org/cinnamon/desktop/wm/preferences" = {
      action-scroll-titlebar = "none";
      audible-bell = false;
      button-layout = ":minimize,maximize,close";
      focus-mode = "click";
      focus-new-windows = "smart";
      min-window-opacity = 30;
      num-workspaces = 1;
      theme = "Mint-Y";
      theme-backup = "Mint-Y";
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

    "org/cinnamon/settings-daemon/plugins/power" = {
      button-power = "nothing";
      critical-battery-action = "nothing";
      lid-close-ac-action = "blank";
      lid-close-battery-action = "suspend";
      sleep-display-ac = 900;
      sleep-display-battery = 300;
      sleep-inactive-ac-timeout = 3600;
      sleep-inactive-battery-timeout = 600;
    };

    "org/cinnamon/settings-daemon/plugins/xsettings" = {
      buttons-have-icons = true;
      hinting = "full";
      menus-have-icons = true;
    };

    "org/cinnamon/sounds" = {
      close-enabled = true;
      close-file = "/usr/share/mint-artwork/sounds/close.oga";
      login-file = "/media/beatlink/Storage/Files/Sounds/Interface Sounds/Steam/860895(1)/steamdeck_startup_v01_A_01-06 - Blip blip swirl whom.wav";
      logout-file = "/usr/share/mint-artwork/sounds/logout.ogg";
      map-enabled = true;
      map-file = "/usr/share/mint-artwork/sounds/map.oga";
      maximize-enabled = true;
      maximize-file = "/usr/share/mint-artwork/sounds/maximize.oga";
      minimize-enabled = true;
      minimize-file = "/media/beatlink/Storage/Files/Sounds/Interface Sounds/Orwell 2/system_datachunk_pickup-sharedassets1.assets-126.wav";
      notification-enabled = true;
      notification-file = "/media/beatlink/Storage/Files/Sounds/Interface Sounds/Steam/860895(1)/deck_ui_achievement_toast.wav";
      plug-file = "/media/beatlink/Storage/Files/Sounds/Interface Sounds/Orwell 2/main_menu_create_profile-sharedassets1.assets-146.wav";
      switch-file = "/usr/share/mint-artwork/sounds/switch.oga";
      tile-file = "/media/beatlink/Storage/Files/Sounds/Interface Sounds/Orwell 2/system_datachunk_pickup-sharedassets1.assets-126.wav";
      unmaximize-enabled = true;
      unplug-file = "/media/beatlink/Storage/Files/Sounds/Interface Sounds/Orwell 2/system_connection_lost_notification-sharedassets1.assets-124.wav";
    };

    "org/cinnamon/theme" = {
      name = "Mint-Y-Dark-Deep-Sky";
    };

  };
}
