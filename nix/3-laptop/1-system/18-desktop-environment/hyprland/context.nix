# Context
#
# Context is the launcher, the application menu and the window switcher. It replaces rofi for all three, and
# takes over from the bar's window list.
#
# It comes from its own flake now rather than a `nix develop` wrapper around the development checkout. The
# overlay puts it in `pkgs.context`, so the keybinds in ./default.nix, the hot corners in ./hot-corners.nix,
# the gestures in ./gestures.nix and the titlebar button in ./window-controls.nix all name the same store
# path. Context is single instance, so a second invocation hands its command line to the running copy over
# D-Bus rather than starting another - which is also how the subcommands below reach it. With no argument it
# raises the launcher.
#
# Settings are declared through Context's own home-manager module, which writes a *drop-in* rather than
# settings.json. Context reads its settings from a chain of files - the drop-ins first, then the file it
# writes itself - and merges them, so what is declared here is a base and anything changed on Context's
# settings screen wins over it and survives the next rebuild. Only the settings named below are written; every
# other setting follows Context's own default and can be changed in the launcher for good. "Reset your
# changes" on the settings screen drops those changes and hands control back to this file.
#
# That is the whole reason this file no longer forces settings.json. Owning that file meant home-manager and
# Context taking turns clobbering it, and every change made on the settings screen was undone at the next
# rebuild.
#
# Subcommands:
#   (none)              raise the launcher
#   switch              pick a context by name
#   switch-window       pick a window in the current context
#   switch-window-all   pick a window across every context
#   previous            return to the last context, the way alt-tab returns to the last window
#   settings            open the settings screen
#   toggle-rail         collapse or expand the sidebar
#   overview            contexts and apps on one screen
#   move-window         send the focused window to another context (the hyprbars button)
#

{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
let
    palette = config.technet.theme.palette;
    cfg = config.technet.context;
in
{
    options.technet.context = {
        transparency = lib.mkOption {
            type = lib.types.numbers.between 0.0 1.0;
            default = 0.75;
            description = ''
                How opaque Context's surfaces are. Matches the bar's. Transparency is the alpha of the
                surface colour, which is the only place GTK can express it: `alpha()` takes a literal rather
                than a named colour.
            '';
        };
    };

    config = {
        nixpkgs.overlays = [ inputs.context.overlays.default ];

        home-manager.users.beatlink = {
            imports = [ inputs.context.homeModules.default ];

            programs.context = {
                enable = true;
                # The overlay's build rather than the flake's own, so there is one Context in the closure.
                # home-manager.useGlobalPkgs is set in nix/0-common/2-users, so this is the system package set
                # and the overlay has already been applied to it.
                package = pkgs.context;

                # This session: the sidebar hides itself and comes back on hover, and the overview is the
                # application menu now that waybar has neither a menu nor a window list. The sidebar is
                # contexts and nothing else. mkDefault, so either can still be set from elsewhere without
                # fighting this.
                #
                # Nothing else is named here. A setting left out is not written at all, so it follows
                # Context's own default until it is changed in the launcher - which is the point of declaring
                # a layer rather than a whole configuration.
                settings = {
                    collapse_mode = lib.mkDefault "hidden";
                    auto_expand = lib.mkDefault true;
                    show_search = lib.mkDefault false;
                    show_saved = lib.mkDefault false;
                    show_apps = lib.mkDefault false;
                };

                # Context loads style.css over its built-in stylesheet - the same contract as waybar's - so
                # its look is declared here from the same palette as the rest of the session. Only the
                # accent-derived colours need spelling out; the translucent overlays Context uses for cards
                # and controls read correctly on any dark surface and are left to its defaults.
                style = ''
                    @define-color ctx_accent #${palette.accent};
                    @define-color ctx_surface rgba(${palette.rgb.surface}, ${toString cfg.transparency});
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
        };
    };
}
