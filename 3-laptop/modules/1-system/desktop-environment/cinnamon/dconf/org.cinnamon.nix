# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/cinnamon" = {
      alttab-switcher-delay = 100;
      alttab-switcher-style = "icons+preview";
      desklet-snap-interval = 25;
      desktop-effects-close = "traditional";
      desktop-effects-map = "traditional";
      desktop-effects-minimize = "traditional";
      device-aliases = [ "/org/freedesktop/UPower/devices/battery_BAT1:=Internal Battery" "/org/freedesktop/UPower/devices/keyboard_hidpp_battery_0:= Wireless Keyboard" ];
      enabled-applets = [ "panel1:left:0:menu@cinnamon.org:172" "panel1:left:1:places-bookmarks@dmo60.de:154" "panel1:center:2:calendar@cinnamon.org:120" "panel1:center:3:cinnamon-timer@jake1164:149" "panel1:center:4:trilium-api@beatlink:145" "panel1:right:1:xapp-status@cinnamon.org:4" "panel1:right:5:show-hide-applets@mohammad-sn:142" "panel1:right:6:systray@cinnamon.org:143" "panel1:right:3:printers@cinnamon.org:134" "panel1:right:7:notifications@cinnamon.org:5" "panel1:right:4:gpaste-reloaded@feuerfuchs.eu:144" "panel1:right:8:sound@cinnamon.org:11" "panel1:right:9:network@cinnamon.org:10" "panel1:right:10:inhibit@cinnamon.org:156" "panel1:right:11:power-profiles@rcalixte:147" "panel1:right:12:power@cinnamon.org:12" "panel1:center:0:weather@mockturtl:0" "panel1:right:0:auto-dark-light@gihaume:3" ];
      enabled-desklets = [];
      enabled-extensions = [ "transparent-panels@germanfr" ];
      hotcorner-layout = [ "expo:false:0" "desktop:true:100" "expo:true:100" "scale:true:100" ];
      next-applet-id = 4;
      panel-zone-icon-sizes = "[{\"panelId\":1,\"left\":16,\"center\":16,\"right\":16}]";
      panel-zone-symbolic-icon-sizes = "[{\"panelId\": 1, \"left\": 16, \"center\": 16, \"right\": 16}]";
      panel-zone-text-sizes = "[{\"panelId\": 1, \"left\": 11.0, \"center\": 11.0, \"right\": 11.0}]";
      panels-autohide = [ "1:false" "2:intel" ];
      panels-enabled = [ "1:0:top" ];
    };

    "org/cinnamon/cinnamon-session" = {
      quit-delay-toggle = true;
      quit-time-delay = 5;
    };

    "org/cinnamon/desktop/a11y/keyboard" = {
      togglekeys-enable-beep = true;
      togglekeys-enable-osd = true;
      togglekeys-sound-off = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/button-toggle-off.ogg";
      togglekeys-sound-on = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/button-toggle-on.ogg";
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
      exec = "/nix/store/m1j5n3s44gaxkrqyhw245fg1kplmagba-tilix-1.9.6/bin/tilix";
      exec-arg = "";
    };

    "org/cinnamon/desktop/background" = {
      picture-options = "zoom";
      picture-uri = "file:///Storage/Files/Pictures/Wallpapers/variety-copied-wallpaper-638b4cd3c029ecab4f49339c5cf90d39.jpg";
    };

    "org/cinnamon/desktop/background/slideshow" = {
      delay = 15;
      image-source = "directory:///Storage/Files/Pictures/Wallpapers";
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
      gtk-theme = "Mint-Y-Aqua";
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
      fullscreen-notifications = true;
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

    "org/cinnamon/desktop/privacy" = {
      recent-files-max-age = 7;
      remember-recent-files = true;
    };

    "org/cinnamon/desktop/screensaver" = {
      allow-media-control = false;
      date-format = " %A, %B %-e %Y";
      font-date = "Noto Sans 24";
      font-message = "Noto Sans 14";
      font-time = "Noto Sans 64";
      lock-enabled = true;
      show-album-art = false;
      show-info-panel = false;
      time-format = "%I:%M:%S %p";
      use-custom-format = true;
    };

    "org/cinnamon/desktop/session" = {
      idle-delay = mkUint32 1800;
    };

    "org/cinnamon/desktop/sound" = {
      allow-amplified-volume = true;
      event-sounds = false;
      maximum-volume = 150;
      volume-sound-enabled = true;
      volume-sound-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/message-new-instant.ogg";
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
    };

    "org/cinnamon/gestures" = {
      enabled = true;
      swipe-down-2 = "PUSH_TILE_DOWN::end";
      swipe-down-3 = "MINIMIZE::::start";
      swipe-down-4 = "TOGGLE_EXPO::::start";
      swipe-left-2 = "PUSH_TILE_LEFT::end";
      swipe-left-3 = "PUSH_TILE_LEFT::::start";
      swipe-left-4 = "WORKSPACE_PREVIOUS::::start";
      swipe-right-2 = "PUSH_TILE_RIGHT::end";
      swipe-right-3 = "PUSH_TILE_RIGHT::::start";
      swipe-right-4 = "WORKSPACE_NEXT::::start";
      swipe-up-2 = "";
      swipe-up-3 = "MAXIMIZE::::start";
      swipe-up-4 = "TOGGLE_OVERVIEW::50::start";
      tap-3 = "";
    };

    "org/cinnamon/launcher" = {
      check-frequency = 60;
      memory-limit = 1024;
      memory-limit-enabled = true;
    };

    "org/cinnamon/muffin" = {
      attach-modal-dialogs = true;
      bring-windows-to-current-workspace = true;
      draggable-border-width = 10;
      experimental-features = [];
      placement-mode = "center";
      resize-threshold = 24;
      tile-maximize = true;
      unredirect-fullscreen-windows = true;
      workspace-cycle = true;
      workspaces-only-on-primary = false;
    };

    "org/cinnamon/nemo/desktop" = {
      fonts = "Noto Sans 12";
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

    "org/cinnamon/settings-daemon/plugins/color" = {
      night-light-enabled = true;
      night-light-last-coordinates = mkTuple [ 17.5805 (-76.4736) ];
      night-light-schedule-from = 18.0;
      night-light-schedule-mode = "manual";
      night-light-schedule-to = 6;
      night-light-temperature = mkUint32 2700;
    };

    "org/cinnamon/settings-daemon/plugins/power" = {
      button-power = "interactive";
      critical-battery-action = "suspend";
      lid-close-ac-action = "blank";
      lid-close-battery-action = "suspend";
      lock-on-suspend = true;
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
      close-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/service-logout.ogg";
      login-enabled = true;
      login-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/desktop-login.ogg";
      logout-enabled = true;
      logout-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/desktop-logout.ogg";
      map-enabled = true;
      map-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/service-login.ogg";
      maximize-enabled = true;
      maximize-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/button-toggle-on.ogg";
      minimize-enabled = true;
      minimize-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/button-pressed.ogg";
      notification-enabled = true;
      notification-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/service-login.ogg";
      plug-enabled = true;
      plug-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/service-login.ogg";
      switch-enabled = true;
      switch-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/message-new-instant.ogg";
      tile-enabled = true;
      tile-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/button-toggle-on.ogg";
      unmaximize-enabled = true;
      unmaximize-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/button-toggle-off.ogg";
      unplug-enabled = true;
      unplug-file = "/Storage/Files/Sounds/Interface Sounds/Linux/Fresh and Clean/stereo/service-logout.ogg";
    };

    "org/cinnamon/theme" = {
      name = "Mint-Y-Dark-Aqua";
    };

  };
}
