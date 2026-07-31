# Window Controls and Stacking Mode
#
# Hyprland draws no titlebars of its own. Applications that use client side decorations (GTK4/libadwaita,
# Electron, Firefox) draw their own controls, while everything expecting the compositor to provide them —
# most GTK3 and Qt apps, and anything running through XWayland — gets none. The result is a session where
# some windows have a close button and others do not.
#
# hyprbars adds a compositor drawn titlebar with buttons, so every window gets the same controls regardless
# of toolkit. It is a plugin, so it is pinned to the exact Hyprland commit it was built against; nixpkgs
# keeps the two in step by building hyprlandPlugins against the same hyprland package.
#
# Cinnamon's muffin uses a floating (stacking) layout, whereas Hyprland tiles by default. Rather than
# choosing one, $mod+T toggles the active window between tiled and floating, and $mod+SHIFT+T flips the
# whole workspace, so the session can be used either way.
#

{ pkgs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            wayland.windowManager.hyprland = {
                plugins = [ pkgs.hyprlandPlugins.hyprbars ];

                settings = {
                    # hyprbars settings live under plugin:hyprbars, not a top level `bar` block.
                    # Colours follow the Mint-Y-Dark-Aqua theme used elsewhere in this config.
                    plugin.hyprbars = {
                        bar_height = 28;
                        bar_color = "rgb(1e1e1e)";
                        "col.text" = "rgb(ffffff)";
                        bar_text_size = 11;
                        bar_text_font = "Noto Sans";
                        bar_part_of_window = true; # Titlebar sits inside the window border, as in Cinnamon
                        bar_precedence_over_border = true;

                        # Buttons are declared right to left, matching Cinnamon's close/maximize/minimize
                        # order in the top right of the titlebar. Hyprland has no minimise concept, so that
                        # button sends the window to a special workspace, which is the closest equivalent.
                        hyprbars-button = [
                            "rgb(e06c75), 14, , hyprctl dispatch killactive"
                            "rgb(e5c07b), 14, , hyprctl dispatch fullscreen 1"
                            "rgb(98c379), 14, , hyprctl dispatch movetoworkspacesilent special:minimised"
                        ];
                    };

                    # Note: this hyprbars build exposes no way to exclude specific windows — neither a
                    # `nobar` window rule nor a bar_blacklist option exists, both are rejected. Apps that
                    # draw their own titlebar (Firefox, VSCodium, Electron) therefore show two. Turning off
                    # their client side decorations is the only fix, and is per application.

                    # No workspace-wide stacking toggle. Floating every window at once fights the dwindle
                    # layout and leaves windows overlapping wherever they happened to be; Context places
                    # windows deliberately instead. $mod+T in hotkeys.nix still floats a single window when
                    # one genuinely needs it.
                    bind = [
                        "$mod, M, togglespecialworkspace, minimised"
                    ];
                };
            };
        };
}
