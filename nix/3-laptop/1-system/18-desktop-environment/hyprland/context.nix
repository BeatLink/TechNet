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

{ config, ... }:
let
    palette = config.technet.theme.palette;
in
{
    # Context loads $XDG_CONFIG_HOME/context/style.css over its built-in stylesheet — the same contract
    # as waybar's style.css — so its look is declared here from the same palette as the rest of the
    # session. Only the accent-derived colours need spelling out; the translucent overlays Context uses
    # for cards and controls read correctly on any dark surface and are left to its defaults.
    home-manager.users.beatlink = {
        xdg.configFile."context/style.css".text = ''
            @define-color ctx_accent #${palette.accent};
            @define-color ctx_surface #${palette.surface};
            @define-color ctx_on_surface #${palette.text};
            @define-color ctx_slot_fill #${palette.accent}52;
            @define-color ctx_slot_fill_active #${palette.accent}80;
            @define-color ctx_slot_border #${palette.accent}b3;
            @define-color ctx_tile_selected #${palette.accent}38;
            @define-color ctx_drop_target #${palette.accent}24;
            @define-color ctx_leaving_border #${palette.accent};
            @define-color ctx_rail_open #${palette.accent}33;
            @define-color ctx_rail_active #${palette.accent}59;
        '';
    };

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
