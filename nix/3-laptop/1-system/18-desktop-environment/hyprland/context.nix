# Context
#
# Context is the launcher, the application menu and the window switcher. It replaces rofi for all three, and
# takes over from the bar's window list.
#
# It runs from the development checkout rather than a package, as it is not packaged yet; nix develop supplies
# pygobject and the layer-shell library it needs. Context is single instance, so a second invocation hands its
# command line to the running copy over D-Bus rather than starting another - which is also how the subcommands
# below reach it. With no argument it raises the launcher.
#
# The wrapper is exposed through pkgs so the keybinds in ./default.nix, the hot corners in ./hot-corners.nix
# and the gestures in ./gestures.nix all refer to the same store path. waycorner and libinput-gestures take a
# command rather than a Hyprland config string, so the $context variable is not available to them.
#
# Subcommands:
#   (none)              raise the launcher
#   switch              pick a context by name
#   switch-window       pick a window in the current context
#   switch-window-all   pick a window across every context
#   previous            return to the last context, the way alt-tab returns to the last window
#   settings            open the settings page
#   toggle-rail         collapse or expand the sidebar
#

{ ... }:
{
    nixpkgs.overlays = [
        (final: prev: {
            context-launcher = final.writeShellApplication {
                name = "context-launcher";
                runtimeInputs = [ final.nix ];
                text = ''
                    cd /Storage/Files/Projects/Coding/Context || exit 1
                    exec nix develop --command python3 -m context "$@"
                '';
            };
        })
    ];
}
