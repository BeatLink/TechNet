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

{ config, pkgs, ... }:
let
    palette = config.technet.theme.palette;
in
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
                        bar_color = "rgb(${palette.surface})";
                        "col.text" = "rgb(${palette.text})";
                        bar_text_size = 11;
                        bar_text_font = "Noto Sans";
                        bar_part_of_window = true; # Titlebar sits inside the window border, as in Cinnamon
                        bar_precedence_over_border = true;

                        # Close and maximise only. There is deliberately no minimise: Hyprland has no
                        # such concept, and parking windows in a special workspace turned out to be a
                        # black hole — while that workspace is open Hyprland treats it as the active
                        # target, so every newly launched window landed there instead of the workspace
                        # that was focused. A context is the place windows belong to now.
                        hyprbars-button = [
                            "rgb(${palette.red}), 14, , hyprctl dispatch killactive"
                            "rgb(${palette.yellow}), 14, , hyprctl dispatch fullscreen 1"
                        ];
                    };

                    # Note: this hyprbars build exposes no way to exclude specific windows — neither a
                    # `nobar` window rule nor a bar_blacklist option exists, both are rejected. Apps that
                    # draw their own titlebar (Firefox, VSCodium, Electron) therefore show two. Turning off
                    # their client side decorations is the only fix, and is per application.

                    # No workspace-wide stacking toggle, and no minimise. Floating everything at once
                    # fights the dwindle layout, and minimising hid windows somewhere the user could not
                    # see. Context places windows deliberately instead; $mod+T in hotkeys.nix still
                    # floats a single window when one genuinely needs it.
                };
            };
        };
}
