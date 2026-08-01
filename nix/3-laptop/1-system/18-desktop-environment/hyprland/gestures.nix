# Touchpad Gestures
#
# Cinnamon's gestures are configured under org/cinnamon/gestures, with an action bound per swipe direction and
# finger count. Hyprland 0.51 onwards has a general gesture system that can bind arbitrary dispatchers to swipes,
# which covers most of the Cinnamon set.
#
# The Cinnamon configuration and how each entry maps here:
#
#   swipe 2 left/right/down  PUSH_TILE_*          - two finger swipes are left to scrolling, as intercepting them
#                                                   would break scrolling in every application
#   swipe 3 left/right       PUSH_TILE_LEFT/RIGHT - movewindow, the tiling equivalent of pushing a window aside
#   swipe 3 up               MAXIMIZE             - the native fullscreen gesture in maximize mode
#   swipe 3 down             MINIMIZE             - Hyprland has no minimize, so the native special workspace
#                                                   gesture is used, which is the closest equivalent and is
#                                                   reversible via the keybind at the bottom of this file
#   swipe 4 left/right       WORKSPACE_PREVIOUS/NEXT - workspace e-1 / e+1
#   swipe 4 up               TOGGLE_OVERVIEW      - the overview from ./overview.nix
#   swipe 4 down             TOGGLE_EXPO          - Cinnamon's expo is the same all workspaces view as its
#                                                   overview, so both map to the same script here
#
# Cinnamon's swipe-percent-threshold is 60 and pinch-percent-threshold is 40. Hyprland expresses this as
# gesture_threshold in pixels rather than a percentage, so a value proportional to a typical touchpad is used.
#

{ pkgs, ... }:
{
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            wayland.windowManager.hyprland.settings = {
                # Hyprland 0.51 replaced the old gestures block with a list of gesture bindings. Each entry is
                # "finger count, direction, dispatcher, args".
                gesture = [
                    "3, left, dispatcher, movewindow, l"
                    "3, right, dispatcher, movewindow, r"
                    # The native fullscreen gesture animates the window as the fingers move, rather than
                    # snapping at the end the way a dispatcher would. 'maximize' keeps the bars visible, which
                    # is what Cinnamon's MAXIMIZE action does.
                    "3, up, fullscreen, maximize"
                    "3, down, special, minimized"
                    # The native workspace gesture follows the fingers and picks a direction from the swipe, so
                    # one entry per axis covers both left and right.
                    "4, horizontal, workspace"
                    "4, up, dispatcher, exec, ${pkgs.context}/bin/context switch-window-all"
                    "4, down, dispatcher, exec, ${pkgs.context}/bin/context switch-window-all"
                ];

                # Cinnamon's swipe-percent-threshold of 60 is a proportion of the touchpad, Hyprland takes a
                # pixel distance. 350 is roughly the same proportion of a typical laptop touchpad.
                gestures.workspace_swipe_distance = 350;

                # Restores a window sent to the special workspace by the three finger down swipe above, since
                # Hyprland has no minimize concept and therefore no unminimize.
                bind = [
                    "$mod SHIFT, M, togglespecialworkspace, minimized"
                ];
            };
        };
}
