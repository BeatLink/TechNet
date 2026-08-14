# Hyprland Settings
#
# This module configures the Hyprland Wayland compositor. Unlike Cinnamon and KDE, Hyprland is not a full desktop
# environment, so the individual pieces (bar, launcher, notifications, lock screen, etc) are configured in the
# submodules imported at the bottom of this file.
#
# Hyprland is configured entirely through home-manager (wayland.windowManager.hyprland) rather than dconf or
# plasma-manager, so the settings live in this repo directly rather than being exported from a running session.
#
# The settings here mirror the Cinnamon configuration in ../cinnamon as closely as Hyprland allows. Where the two
# differ deliberately it is noted inline. The largest deliberate divergence is workspaces: Cinnamon runs a single
# workspace with floating windows, while this configuration uses five workspaces with dwindle tiling.
#

{ config, pkgs, ... }:
let
    palette = config.technet.theme.palette;
in
{
    programs.hyprland = {
        enable = true; # Enables Hyprland and its NixOS session/portal wiring
        withUWSM = true; # Launches Hyprland under a systemd user session so user services start reliably
        xwayland.enable = true; # Enables X11 application support
    };

    services = {
        # No display manager is declared here. LightDM is enabled by the cinnamon module and already scans
        # wayland-sessions alongside xsessions, so it lists Hyprland as well and both can be imported at once.
        # Declaring SDDM here too would enable two display managers competing for the same VT.
        libinput.enable = true; # Enables Touchpad Functionality
        gnome.gnome-keyring.enable = true; # Provides a secret service, normally supplied by the DE
        gvfs.enable = true; # Trash, mounting and network shares for the file manager
        upower.enable = true; # Battery status for the bar and idle daemon
    };

    security.pam.services.hyprlock = { }; # Allows hyprlock to authenticate and unlock the session

    # Nvidia Optimus requires these to be set for Wayland clients to pick the correct backend, or Firefox
    # ignores the hardware cursor. Toolkit backends are not handled here; ../wayland.nix covers every session.
    environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
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
                    "$terminal" = "${pkgs.tilix}/bin/tilix"; # Matches desktop/applications/terminal from dconf
                    "$fileManager" = "${pkgs.nemo}/bin/nemo";
                    # Application launching and window switching are both Context's job now. Which
                    # build is in use is decided in ./context.nix, so the keybinds here, the hot
                    # corners and the gestures all refer to the same one.
                    "$context" = "${config.technet.context.package}/bin/context";
                    # Kills it and starts it again, for when it has stopped answering and the
                    # `restart` subcommand — which needs it to answer — cannot reach it.
                    "$contextRestart" = "${config.technet.context.restart}/bin/context-hard-restart";

                    # hyprpaper, swaync and hypridle are each started by their own home-manager systemd user
                    # service. Listing them here as well launched a second copy that raced the service: swaync
                    # exited with "An instance is already running" and hit its restart limit. Only the clipboard
                    # watcher, which home-manager has no service for, is started here.
                    exec-once = [
                        "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store"
                    ];

                    # Cinnamon uses a cursor-size of 5 in dconf, which is a Cinnamon specific scale rather than a
                    # pixel count. Hyprland takes pixels, so the equivalent default of 24 is used here.
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
                        # Both borders are the look's accent - Mint-Y-Aqua by default - so every edge on the
                        # screen is the same colour and focus is told by how strong it is rather than by a
                        # change of hue. The unfocused alpha is low enough that a wall of windows does not
                        # read as a grid of aqua boxes, and high enough to still draw the edge.
                        "col.active_border" = "rgba(${palette.accent}ee)";
                        "col.inactive_border" = "rgba(${palette.accent}55)";
                        # Cinnamon's muffin draggable-border-width is 10, which covers the whole frame edge. The
                        # closest Hyprland equivalent is extending the resize region beyond the visible border.
                        resize_on_border = true;
                        extend_border_grab_area = 10;
                        layout = "dwindle";
                    };

                    decoration = {
                        rounding = 8;
                        # Cinnamon's muffin min-window-opacity is 30, ie 30% is the floor for manually dimmed
                        # windows. Hyprland has no user opacity keybind by default so inactive windows are left
                        # fully opaque to match how Cinnamon actually renders them day to day.
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

                    # Cinnamon's desktop-effects-map/minimize/close are all set to 'traditional', a short scale
                    # and fade rather than an elaborate effect. These durations approximate that.
                    animations = {
                        enabled = true;
                        bezier = [ "smooth, 0.05, 0.9, 0.1, 1.0" ];
                        animation = [
                            "windows, 1, 4, smooth, popin 80%"
                            "fade, 1, 5, default"
                            "workspaces, 1, 4, smooth, slide"
                        ];
                    };

                    input = {
                        kb_layout = "us"; # Matches desktop/input-sources sources=[('xkb', 'us')]
                        follow_mouse = 0; # Cinnamon focus-mode is 'click', so focus does not follow the pointer
                        repeat_delay = 570; # desktop/peripherals/keyboard delay
                        repeat_rate = 53; # 1000ms / repeat-interval of 19ms, Hyprland takes a rate not an interval
                        numlock_by_default = false; # desktop/peripherals/keyboard numlock-state=false
                        accel_profile = "adaptive"; # desktop/peripherals/mouse accel-profile='default'
                        touchpad = {
                            # desktop/peripherals/touchpad natural-scroll=true. The mouse is left inverted to
                            # match desktop/peripherals/mouse natural-scroll=false.
                            natural_scroll = true;
                            tap-to-click = true; # desktop/peripherals/touchpad tap-to-click=true
                            disable_while_typing = true; # desktop/peripherals/touchpad disable-while-typing=true
                            clickfinger_behavior = true; # desktop/peripherals/touchpad click-method='fingers'
                        };
                    };

                    dwindle = {
                        # dwindle:pseudotile was removed in Hyprland 0.56. Pseudotiling is now reached through
                        # the `pseudo` dispatcher per window rather than a layout-wide default.
                        preserve_split = true;
                    };

                    misc = {
                        disable_hyprland_logo = true;
                        disable_splash_rendering = true;
                        force_default_wallpaper = 0;
                        # Cinnamon's muffin bring-windows-to-current-workspace is true, so activating a window
                        # pulls it to the active workspace rather than switching away from it.
                        focus_on_activate = true;
                    };

                    # Hyprland 0.53 overhauled window rules: windowrulev2 is deprecated in favour of
                    # windowrule, matchers moved behind a `match:` prefix, and effects now take an explicit
                    # value. suppressevent was also renamed to suppress_event.
                    windowrule = [
                        "match:class .*, suppress_event maximize"
                        # Cinnamon's muffin attach-modal-dialogs is true, so dialogs are centered on their parent
                        "match:float 1, center on"
                        "match:class ^(pavucontrol|blueman-manager|nm-connection-editor)$, float on"
                        "match:class ^(org.keepassxc.KeePassXC)$, match:title ^(Unlock Database.*)$, float on"
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
                    # mimeapps.list is deliberately not listed here. The cinnamon module already persists it,
                    # and impermanence rejects the same file being claimed twice. Default applications are a
                    # user preference rather than a session one, so sharing the Cinnamon copy is correct.
                };
            };

            # GTK applications follow the chosen look (technet.theme). Hyprland has no settings daemon of
            # its own to apply a theme, so home-manager writes the settings files directly. Cinnamon is
            # unaffected: its xsettings daemon applies the dconf theme over these files.
            gtk = {
                enable = true;
                theme = {
                    name = palette.gtk.name;
                    package = palette.gtk.package;
                };
                iconTheme = {
                    name = palette.icons.name;
                    package = palette.icons.package;
                };
                font = {
                    name = "Noto Sans"; # desktop/interface font-name='Noto Sans 12'
                    size = 12;
                };
                gtk3.extraConfig = {
                    gtk-menu-images = true; # settings-daemon/plugins/xsettings menus-have-icons=true
                    gtk-button-images = true; # settings-daemon/plugins/xsettings buttons-have-icons=true
                    gtk-xft-hinting = 1;
                    gtk-xft-hintstyle = "hintfull"; # settings-daemon/plugins/xsettings hinting='full'
                };
            };
        };

    imports = [
        # Import Other Modules
        ./context.nix
        ./hotkeys.nix
        ./window-controls.nix
        ./edge-snap.nix
        ./waybar.nix
        ./notifications.nix
        ./screenlock.nix
        ./lid.nix
        ./wallpaper.nix
        ./screenshot.nix
        ./overview.nix
        ./hot-corners.nix
        ./gestures.nix
        ./sounds.nix
        ./night-light.nix
        ./osd.nix
        ./scripts.nix
    ];
}
