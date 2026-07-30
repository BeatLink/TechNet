# Overview
#
# KDE's Overview effect showed every window across every virtual desktop in a single zoomed out grid. Hyprland has
# no equivalent built in, and the plugins that provide one (hyprexpo, Hyprspace) do not build against Hyprland
# 0.56 - the 0.56 release moved windows into the Desktop::View namespace and removed most of the CCompositor
# accessors those plugins call, so they fail to compile rather than merely misbehaving.
#
# Instead the overview is built from hyprctl and rofi, which are already part of this configuration. The script
# lists every window on every workspace and hands it to rofi, so a selection jumps to that window regardless of
# which workspace it lives on. This covers the same "show me everything and let me pick" workflow as the KDE
# effect, without a compositor plugin.
#
# The scripts are exposed through pkgs by the overlay below so that both the keybind here and the hot corners in
# ./hot-corners.nix refer to the same store paths.
#

{ ... }:
{
    nixpkgs.overlays = [
        (final: prev: {
            # Lists all windows as "workspace: title (class)" and focuses the chosen one by its window address,
            # which is stable even when several windows share a title. The address is kept in the first column
            # and hidden from display, so it can be recovered from the selection without reparsing the title.
            hypr-overview = final.writeShellApplication {
                name = "hypr-overview";
                runtimeInputs = with final; [
                    hyprland
                    rofi
                    jq
                ];
                text = ''
                    selection=$(
                        hyprctl -j clients \
                            | jq -r '
                                map(select(.mapped))
                                | sort_by(.workspace.id)
                                | .[]
                                | "\(.address)\t[\(.workspace.name)] \(.title) (\(.class))"
                            ' \
                            | rofi -dmenu -i -p "Overview" -display-column-separator '\t' -display-columns 2
                    )

                    [ -n "$selection" ] || exit 0
                    hyprctl dispatch focuswindow "address:''${selection%%$'\t'*}"
                '';
            };

            # Toggles between a dedicated empty workspace and whatever workspace was active before, so the show
            # desktop hot corner in ./hot-corners.nix can both hide and restore the windows.
            hypr-show-desktop = final.writeShellApplication {
                name = "hypr-show-desktop";
                runtimeInputs = with final; [
                    hyprland
                    jq
                ];
                text = ''
                    desktop=99
                    current=$(hyprctl -j activeworkspace | jq -r '.id')

                    if [ "$current" = "$desktop" ]; then
                        hyprctl dispatch workspace previous
                    else
                        hyprctl dispatch workspace "$desktop"
                    fi
                '';
            };
        })
    ];

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home.packages = [
                pkgs.hypr-overview
                pkgs.hypr-show-desktop
            ];

            wayland.windowManager.hyprland.settings.bind = [
                "$mod, grave, exec, ${pkgs.hypr-overview}/bin/hypr-overview"
            ];
        };
}
