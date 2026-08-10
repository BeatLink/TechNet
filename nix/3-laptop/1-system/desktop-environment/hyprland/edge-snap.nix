# Edge Snapping
#
# Cinnamon's muffin tiles a window when it is dragged against a screen edge: left or right half, quarter at
# a corner, and maximised at the top. Hyprland has nothing equivalent — general:snap only snaps floating
# windows to each other, and Aero Snap is still an open feature request upstream
# (hyprwm/Hyprland discussion #13838).
#
# This implements it as a small daemon. Hyprland's event socket announces when a drag finishes, at which
# point the cursor position decides what to do:
#
#     top edge                   maximise
#     left / right edge          half screen
#     any corner                 quarter screen
#     anywhere else              leave the window alone
#
# Only floating windows are touched: dragging a tiled window is how the dwindle layout is rearranged, and
# snapping those would fight the layout.
#

{ ... }:
{
    nixpkgs.overlays = [
        (final: prev: {
            hypr-edge-snap = final.writeShellApplication {
                name = "hypr-edge-snap";
                runtimeInputs = with final; [
                    hyprland
                    jq
                    socat
                    coreutils
                ];
                text = ''
                    # How close to an edge counts as touching it, in pixels.
                    THRESHOLD=''${HYPR_SNAP_THRESHOLD:-24}

                    snap() {
                        # $1..$4: x y w h as percentages of the monitor
                        hyprctl --batch "\
                            dispatch setfloating active ; \
                            dispatch resizeactive exact $3% $4% ; \
                            dispatch moveactive exact $1% $2%" >/dev/null 2>&1
                    }

                    handle_drag_end() {
                        # Only act on floating windows; tiled drags belong to the layout.
                        window=$(hyprctl -j activewindow)
                        [ "$(jq -r '.floating' <<<"$window")" = "true" ] || return 0

                        monitor=$(hyprctl -j monitors | jq -r '.[] | select(.focused == true)')
                        mx=$(jq -r '.x' <<<"$monitor")
                        my=$(jq -r '.y' <<<"$monitor")
                        mw=$(jq -r '.width' <<<"$monitor")
                        mh=$(jq -r '.height' <<<"$monitor")

                        cursor=$(hyprctl -j cursorpos)
                        cx=$(( $(jq -r '.x' <<<"$cursor") - mx ))
                        cy=$(( $(jq -r '.y' <<<"$cursor") - my ))

                        left=0;  [ "$cx" -le "$THRESHOLD" ] && left=1
                        right=0; [ "$cx" -ge $(( mw - THRESHOLD )) ] && right=1
                        top=0;   [ "$cy" -le "$THRESHOLD" ] && top=1
                        bottom=0; [ "$cy" -ge $(( mh - THRESHOLD )) ] && bottom=1

                        if   [ "$top" = 1 ] && [ "$left" = 1 ];    then snap 0 0 50 50
                        elif [ "$top" = 1 ] && [ "$right" = 1 ];   then snap 50 0 50 50
                        elif [ "$bottom" = 1 ] && [ "$left" = 1 ]; then snap 0 50 50 50
                        elif [ "$bottom" = 1 ] && [ "$right" = 1 ];then snap 50 50 50 50
                        elif [ "$top" = 1 ]; then
                            # Maximise rather than fullscreen, so the bars stay visible as in Cinnamon.
                            hyprctl dispatch fullscreenstate 0 2 >/dev/null 2>&1
                        elif [ "$left" = 1 ];  then snap 0 0 50 100
                        elif [ "$right" = 1 ]; then snap 50 0 50 100
                        fi
                    }

                    socket="''${XDG_RUNTIME_DIR}/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
                    socat -U - "UNIX-CONNECT:$socket" | while read -r line; do
                        case "$line" in
                            # Emitted when a window stops being dragged.
                            changefloatingmode*|movewindow*) handle_drag_end ;;
                        esac
                    done
                '';
            };
        })
    ];

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            systemd.user.services.hypr-edge-snap = {
                Unit = {
                    Description = "Cinnamon style edge snapping for Hyprland";
                    PartOf = [ "graphical-session.target" ];
                    After = [ "graphical-session.target" ];
                };
                Service = {
                    ExecStart = "${pkgs.hypr-edge-snap}/bin/hypr-edge-snap";
                    Restart = "on-failure";
                    RestartSec = 2;
                };
                Install.WantedBy = [ "graphical-session.target" ];
            };
        };
}
