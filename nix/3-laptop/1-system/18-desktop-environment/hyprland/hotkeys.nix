# Hyprland Keybindings
#
# Keybinds are split out from the main config so they can be edited without touching the compositor settings.
# The $mod, $terminal, $fileManager and $menu variables are defined in ./default.nix.
#

{ pkgs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            wayland.windowManager.hyprland.settings = {
                bind = [
                    # Applications
                    "$mod, Return, exec, $terminal"
                    "$mod, E, exec, $fileManager"
                    "$mod, Space, exec, $menu"
                    "$mod, V, exec, ${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi}/bin/rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy"

                    # Session
                    "$mod, Q, killactive,"
                    "$mod SHIFT, Q, exit,"
                    "$mod, L, exec, ${pkgs.hyprlock}/bin/hyprlock"
                    "CTRL ALT, Backspace, exec, ${pkgs.systemd}/bin/systemctl restart display-manager.service"

                    # Window management
                    "$mod, F, fullscreen,"
                    "$mod, T, togglefloating,"
                    "$mod, P, pseudo,"
                    "$mod, J, togglesplit,"

                    # Focus
                    "$mod, left, movefocus, l"
                    "$mod, right, movefocus, r"
                    "$mod, up, movefocus, u"
                    "$mod, down, movefocus, d"

                    # Move windows
                    "$mod SHIFT, left, movewindow, l"
                    "$mod SHIFT, right, movewindow, r"
                    "$mod SHIFT, up, movewindow, u"
                    "$mod SHIFT, down, movewindow, d"

                    # Workspaces
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
                    "$mod, Tab, workspace, e+1"
                    "$mod SHIFT, Tab, workspace, e-1"

                    # Window switcher, replaces the KDE hot corner / present windows workflow. Rofi's window mode
                    # sorts by most recently used, unlike KDE's Present Windows effect. The cross workspace
                    # overview is bound to $mod+grave in ./overview.nix.
                    "$mod, W, exec, ${pkgs.rofi}/bin/rofi -show window"
                ];

                # Repeatable binds for hardware keys
                bindel = [
                    ", XF86AudioRaiseVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
                    ", XF86AudioLowerVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
                    ", XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%+"
                    ", XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%-"
                ];

                bindl = [
                    ", XF86AudioMute, exec, ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
                    ", XF86AudioMicMute, exec, ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
                    ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
                    ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
                    ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
                ];

                # Mouse binds for moving and resizing windows
                bindm = [
                    "$mod, mouse:272, movewindow"
                    "$mod, mouse:273, resizewindow"
                ];
            };
        };
}
