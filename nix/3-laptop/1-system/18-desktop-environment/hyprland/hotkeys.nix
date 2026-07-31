# Hyprland Keybindings
#
# Keybinds are split out from the main config so they can be edited without touching the compositor settings.
# The $mod, $terminal, $fileManager and $context variables are defined in ./default.nix.
#
# These mirror the Cinnamon keybindings from dconf (org/cinnamon/desktop/keybindings) so muscle memory carries
# over. Bindings that have no Hyprland equivalent are noted where they are omitted.
#
# Cinnamon binds that are deliberately not reproduced:
#   switch-panels / switch-panels-backward - Hyprland has no panel focus concept, waybar is not keyboard focusable
#   toggle-recording                       - handled by the screen recorder rather than the compositor
#   activate-window-menu                   - Hyprland has no server side window menu
#   rotate-monitor                         - hyprctl can rotate but the laptop has no rotation sensor configured
#

{ pkgs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            wayland.windowManager.hyprland.settings = {
                # Cinnamon opens its menu on Super alone. Hyprland can only bind a bare modifier on release,
                # via bindr, so that it does not fire while Super is held as part of another shortcut.
                # This raises Context, which is the launcher now.
                bindr = [ "SUPER, SUPER_L, exec, $context" ];

                bind = [
                    # Applications
                    # Cinnamon binds the terminal to Ctrl+Alt+T (media-keys terminal) and the file manager to
                    # Super+E (media-keys home). Super+Return is kept as an extra Hyprland convention.
                    "CTRL ALT, T, exec, $terminal"
                    "$mod, Return, exec, $terminal"
                    "$mod, E, exec, $fileManager"
                    ", XF86Explorer, exec, $fileManager"
                    "$mod, Space, exec, $context"
                    "$mod, C, exec, $context"
                    "ALT, F2, exec, ${pkgs.rofi}/bin/rofi -show run" # Cinnamon panel-run-dialog
                    "$mod, V, exec, ${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi}/bin/rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy"

                    # Custom keybindings from Cinnamon's custom-keybindings list. xkill has no Wayland equivalent,
                    # so hyprctl kill is used, which puts the pointer into a kill-a-window mode the same way.
                    "CTRL ALT, X, exec, ${pkgs.hyprland}/bin/hyprctl kill"
                    ", XF86HomePage, exec, trilium"

                    # Session
                    # Cinnamon locks with Ctrl+Alt+L, Super+L and XF86ScreenSaver (media-keys screensaver)
                    "CTRL ALT, L, exec, ${pkgs.hyprlock}/bin/hyprlock"
                    "$mod, L, exec, ${pkgs.hyprlock}/bin/hyprlock"
                    ", XF86ScreenSaver, exec, ${pkgs.hyprlock}/bin/hyprlock"
                    "$mod SHIFT, Q, exit,"
                    "CTRL ALT, Backspace, exec, ${pkgs.systemd}/bin/systemctl restart display-manager.service"

                    # Window management. Cinnamon closes with Alt+F4 (wm close), toggles maximize with Alt+F10
                    # and unmaximizes with Alt+F5.
                    "ALT, F4, killactive,"
                    "$mod, Q, killactive,"
                    "ALT, F10, fullscreenstate, 0 2" # Maximize within the layout, not true fullscreen
                    "ALT, F5, fullscreenstate, 0 0" # Restore, matching Cinnamon's unmaximize
                    "$mod, F, fullscreen,"
                    "$mod, T, togglefloating,"
                    # The standalone togglesplit dispatcher was removed in Hyprland 0.56; it is now a
                    # layout message, so it has to be sent through layoutmsg.
                    "$mod, J, layoutmsg, togglesplit"
                    "ALT, F7, exec, ${pkgs.hyprland}/bin/hyprctl dispatch movewindow" # Cinnamon begin-move
                    "ALT, F8, exec, ${pkgs.hyprland}/bin/hyprctl dispatch resizewindow" # Cinnamon begin-resize

                    # Show desktop, Cinnamon binds this to Super+D (wm show-desktop)
                    "$mod, D, exec, ${pkgs.hypr-show-desktop}/bin/hypr-show-desktop"

                    # Window switching. Cinnamon uses Alt+Tab (switch-windows) with an icons+preview switcher and
                    # Alt+Above_Tab (switch-group) to cycle windows of the same application.
                    "ALT, Tab, cyclenext,"
                    "ALT, Tab, bringactivetotop,"
                    "ALT SHIFT, Tab, cyclenext, prev"
                    "ALT SHIFT, Tab, bringactivetotop,"
                    "ALT, grave, cyclenext, sameclass"
                    "ALT, grave, bringactivetotop,"

                    # Tiling. Cinnamon binds Super+arrows to push-tile-left/right/up/down, which snaps the window
                    # to that half of the screen. In a tiling layout the equivalent is moving the window there.
                    "$mod, left, movewindow, l"
                    "$mod, right, movewindow, r"
                    "$mod, up, movewindow, u"
                    "$mod, down, movewindow, d"

                    # Focus. Cinnamon has no directional focus binds, these follow Hyprland convention.
                    "$mod ALT, left, movefocus, l"
                    "$mod ALT, right, movefocus, r"
                    "$mod ALT, up, movefocus, u"
                    "$mod ALT, down, movefocus, d"

                    # Monitors, matching Cinnamon's move-to-monitor-right/up and switch-monitor
                    "$mod SHIFT, right, movecurrentworkspacetomonitor, r"
                    "$mod SHIFT, up, movecurrentworkspacetomonitor, u"
                    "$mod, P, exec, ${pkgs.wdisplays}/bin/wdisplays" # Cinnamon switch-monitor
                    ", XF86Display, exec, ${pkgs.wdisplays}/bin/wdisplays"

                    # Workspaces. Cinnamon runs a single workspace (num-workspaces=1) so these have no direct
                    # equivalent, but Cinnamon's switch-to-workspace-left/right are Ctrl+Alt+arrows and
                    # move-to-workspace-left/right are Ctrl+Shift+Alt+arrows, so those are kept for consistency.
                    "$mod, 1, workspace, 1"
                    "$mod, 2, workspace, 2"
                    "$mod, 3, workspace, 3"
                    "$mod, 4, workspace, 4"
                    "$mod, 5, workspace, 5"
                    "$mod SHIFT, 1, movetoworkspace, 1"
                    "$mod SHIFT, 2, movetoworkspace, 2"
                    "$mod SHIFT, 3, movetoworkspace, 3"
                    "$mod SHIFT, 4, movetoworkspace, 4"
                    "$mod SHIFT, 5, movetoworkspace, 5"
                    "CTRL ALT, left, workspace, e-1"
                    "CTRL ALT, right, workspace, e+1"
                    "CTRL SHIFT ALT, left, movetoworkspace, e-1"
                    "CTRL SHIFT ALT, right, movetoworkspace, e+1"
                    "$mod, Tab, workspace, e+1"
                    "$mod SHIFT, Tab, workspace, e-1"

                    # Window switcher, the closest equivalent to Cinnamon's alttab-switcher with previews. Rofi's
                    # window mode sorts by most recently used. The cross workspace overview is bound to
                    # $mod+grave in ./overview.nix.
                    "$mod, W, exec, ${pkgs.rofi}/bin/rofi -show window"
                ];

                # The volume, microphone and brightness keys are bound in ./osd.nix rather than here, as they
                # go through swayosd-client so that changing them also draws an on screen popup the way
                # Cinnamon does.

                # Cinnamon binds play to AudioPlay and next to AudioNext (media-keys), and leaves pause unbound.
                # XF86AudioMedia is bound to the media player in Cinnamon; playerctl covers whichever player is
                # running rather than hardcoding one.
                bindl = [
                    ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
                    ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
                    ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
                    ", XF86AudioMedia, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
                ];

                # Mouse binds for moving and resizing windows
                bindm = [
                    "$mod, mouse:272, movewindow"
                    "$mod, mouse:273, resizewindow"
                ];
            };

            home.packages = [ pkgs.wdisplays ]; # Monitor arrangement, replaces Cinnamon's display settings panel
        };
}
