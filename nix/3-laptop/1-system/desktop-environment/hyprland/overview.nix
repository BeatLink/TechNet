# Overview
#
# KDE's Overview effect showed every window across every virtual desktop in a single zoomed out grid. Hyprland has
# no equivalent built in, and the plugins that provide one (hyprexpo, Hyprspace) do not build against Hyprland
# 0.56 - the 0.56 release moved windows into the Desktop::View namespace and removed most of the CCompositor
# accessors those plugins call, so they fail to compile rather than merely misbehaving.
#
# The cross workspace window picker is Context's job now - it lists every window with its context and focuses
# the chosen one, which is the same "show me everything and let me pick" workflow without a compositor plugin
# and without rofi. Only the show desktop toggle remains here.
#
# The script is exposed through pkgs by the overlay below so that both the keybind here and the hot corners in
# ./hot-corners.nix refer to the same store path.
#

{ ... }:
{
    nixpkgs.overlays = [
        (final: prev: {
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
                pkgs.hypr-show-desktop
            ];

            wayland.windowManager.hyprland.settings.bind = [
                "$mod, grave, exec, $context switch-window-all" # Every window, across every context
            ];
        };
}
