# Hyprland Settings
#
# This module configures the Hyprland Wayland compositor. Unlike Cinnamon and KDE, Hyprland is not a full desktop
# environment, so the individual pieces (bar, launcher, notifications, lock screen, etc) are configured in the
# submodules imported at the bottom of this file.
#
# Hyprland is configured entirely through home-manager (wayland.windowManager.hyprland) rather than dconf or
# plasma-manager, so the settings live in this repo directly rather than being exported from a running session.
#

{ pkgs, ... }:
{
    programs.hyprland = {
        enable = true; # Enables Hyprland and its NixOS session/portal wiring
        withUWSM = true; # Launches Hyprland under a systemd user session so user services start reliably
        xwayland.enable = true; # Enables X11 application support
    };

    services = {
        displayManager.sddm = {
            # Enable SDDM Login Manager. SDDM is used here instead of LightDM as it supports Wayland sessions
            enable = true;
            wayland.enable = true;
        };
        libinput.enable = true; # Enables Touchpad Functionality
        gnome.gnome-keyring.enable = true; # Provides a secret service, normally supplied by the DE
        gvfs.enable = true; # Trash, mounting and network shares for the file manager
        upower.enable = true; # Battery status for the bar and idle daemon
    };

    security.pam.services.hyprlock = { }; # Allows hyprlock to authenticate and unlock the session

    # Nvidia Optimus requires these to be set for Wayland clients to pick the correct backend. Without them
    # Electron/Chromium apps fall back to XWayland and Firefox ignores the hardware cursor.
    environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        MOZ_ENABLE_WAYLAND = "1";
    };

    environment.systemPackages = with pkgs; [
        gnome-themes-extra
        libnotify
        ddcutil
        i2c-tools
        brightnessctl
        playerctl # Media keys
        wl-clipboard # Clipboard access for wayland clients
        xdg-utils
    ];

    xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [ xdg-desktop-portal-gtk ]; # GTK portal for file pickers and settings
    };

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            wayland.windowManager.hyprland = {
                enable = true;
                systemd.enable = false; # Handled by UWSM above
                xwayland.enable = true;
                configType = "hyprlang"; # Keeps the legacy config format, matching this system's stateVersion
                settings = {
                    monitor = [
                        ",preferred,auto,1" # Fallback rule; add explicit rules per monitor as needed
                    ];

                    "$mod" = "SUPER";
                    "$terminal" = "${pkgs.tilix}/bin/tilix";
                    "$fileManager" = "${pkgs.nemo}/bin/nemo";
                    "$menu" = "${pkgs.rofi}/bin/rofi -show drun";

                    exec-once = [
                        "${pkgs.waybar}/bin/waybar"
                        "${pkgs.hyprpaper}/bin/hyprpaper"
                        "${pkgs.swaynotificationcenter}/bin/swaync"
                        "${pkgs.hypridle}/bin/hypridle"
                        "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store"
                    ];

                    env = [
                        "XCURSOR_THEME,Bibata-Modern-Classic"
                        "XCURSOR_SIZE,24"
                        "HYPRCURSOR_THEME,Bibata-Modern-Classic"
                        "HYPRCURSOR_SIZE,24"
                    ];

                    general = {
                        gaps_in = 4;
                        gaps_out = 8;
                        border_size = 2;
                        "col.active_border" = "rgba(5ac0c0ee)"; # Mint-Y-Aqua accent, matches the Cinnamon theme
                        "col.inactive_border" = "rgba(444444aa)";
                        resize_on_border = true;
                        layout = "dwindle";
                    };

                    decoration = {
                        rounding = 8;
                        blur = {
                            enabled = true;
                            size = 6;
                            passes = 2;
                        };
                        shadow = {
                            enabled = true;
                            range = 12;
                            render_power = 3;
                        };
                    };

                    animations = {
                        enabled = true;
                        bezier = [ "smooth, 0.05, 0.9, 0.1, 1.0" ];
                        animation = [
                            "windows, 1, 4, smooth"
                            "fade, 1, 5, default"
                            "workspaces, 1, 4, smooth, slide"
                        ];
                    };

                    input = {
                        kb_layout = "us";
                        follow_mouse = 1;
                        touchpad = {
                            natural_scroll = true;
                            tap-to-click = true;
                            disable_while_typing = true;
                        };
                    };

                    gestures.workspace_swipe = true;

                    dwindle = {
                        pseudotile = true;
                        preserve_split = true;
                    };

                    misc = {
                        disable_hyprland_logo = true;
                        disable_splash_rendering = true;
                        force_default_wallpaper = 0;
                    };

                    windowrulev2 = [
                        "suppressevent maximize, class:.*"
                        "float, class:^(pavucontrol|blueman-manager|nm-connection-editor)$"
                        "float, class:^(org.keepassxc.KeePassXC)$, title:^(Unlock Database.*)$"
                    ];
                };
            };

            home = {
                packages = with pkgs; [
                    hyprpicker # Colour picker
                    cliphist # Clipboard history
                    wev # Key event viewer, useful when adding keybinds
                    brightnessctl
                    playerctl
                ];
                pointerCursor = {
                    enable = true;
                    name = "Bibata-Modern-Classic";
                    package = pkgs.bibata-cursors;
                    size = 24;
                    gtk.enable = true;
                };
                persistence."/Storage/Apps/System/Hyprland" = {
                    directories = [
                        ".local/share/cliphist"
                    ];
                    files = [
                        ".config/mimeapps.list"
                    ];
                };
            };
        };

    imports = [
        # Import Other Modules
        ./hotkeys.nix
        ./waybar.nix
        ./rofi.nix
        ./notifications.nix
        ./screenlock.nix
        ./wallpaper.nix
        ./screenshot.nix
    ];
}
