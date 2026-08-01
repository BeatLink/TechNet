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
# Everything Context can be configured with is an option here: `technet.context.settings` writes its
# settings.json, and `technet.context.contexts` declares contexts it takes in the first time it sees them.
# Both files are read by Context rather than managed by it - a declared context is a seed, ordinary once
# taken in, so editing or forgetting one in the launcher sticks.
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

{ config, lib, pkgs, ... }:
let
    palette = config.technet.theme.palette;
    cfg = config.technet.context;

    # One context as Context's own file wants it. Everything but the title is optional; a context with no
    # layout is given the preset for however many applications it holds the first time it opens.
    contextType = lib.types.submodule {
        options = {
            title = lib.mkOption {
                type = lib.types.str;
                description = "What you are doing - the name the launcher lists it under.";
            };
            apps = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                example = [
                    "firefox.desktop"
                    "codium.desktop"
                ];
                description = "Desktop entry ids, in the order they should tile.";
            };
            urls = lib.mkOption {
                type = lib.types.attrsOf (lib.types.listOf lib.types.str);
                default = { };
                example = {
                    "firefox.desktop" = [ "https://github.com" ];
                };
                description = "What each application opens, by desktop entry id.";
            };
            ephemeral = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Discard this context after use.";
            };
            isolated = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Launch its applications under a private session bus.";
            };
        };
    };

    declared = {
        contexts = map (ctx: {
            inherit (ctx) title ephemeral isolated;
            resources = map (app: {
                app_id = app;
                urls = ctx.urls.${app} or [ ];
            }) ctx.apps;
        }) cfg.contexts;
    };
in
{
    options.technet.context = {
        settings = lib.mkOption {
            type = lib.types.submodule {
                # Freeform, so a setting added to Context is usable here the day it lands rather than after
                # this module is taught about it. The named options below are the ones worth spelling out -
                # a default worth changing, or a set of values worth documenting.
                freeformType = (pkgs.formats.json { }).type;
                options = {
                    sidebar_edge = lib.mkOption {
                        type = lib.types.enum [
                            "left"
                            "right"
                            "top"
                            "bottom"
                        ];
                        default = "left";
                        description = "Which side of the screen the launcher docks to.";
                    };
                    monitor = lib.mkOption {
                        type = lib.types.str;
                        default = "";
                        example = "eDP-1";
                        description = ''
                            Which output it docks to. Empty leaves the choice to the compositor, "*" puts a
                            launcher on every screen, anything else is a connector name.
                        '';
                    };
                    sidebar_width = lib.mkOption {
                        type = lib.types.ints.between 200 1200;
                        default = 380;
                        description = "Pixels the expanded launcher reserves.";
                    };
                    rail_width = lib.mkOption {
                        type = lib.types.ints.between 36 160;
                        default = 56;
                        description = "Pixels the collapsed rail reserves.";
                    };
                    collapse_mode = lib.mkOption {
                        type = lib.types.enum [
                            "rail"
                            "hidden"
                            "none"
                        ];
                        default = "rail";
                        description = ''
                            What collapsing does: shrink to a rail of icons, hide entirely behind a sliver to
                            hover over, or offer no collapsing at all.
                        '';
                    };
                    auto_expand = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                        description = "Open the launcher while the pointer is over it.";
                    };
                    auto_expand_delay_ms = lib.mkOption {
                        type = lib.types.ints.between 0 2000;
                        default = 120;
                        description = "How long to hover before it expands.";
                    };
                    collapse_delay_ms = lib.mkOption {
                        type = lib.types.ints.between 0 5000;
                        default = 400;
                        description = "How long it stays open after the pointer leaves its zone.";
                    };
                    save_prompt = lib.mkOption {
                        type = lib.types.enum [
                            "never"
                            "change"
                            "switch"
                            "close"
                        ];
                        default = "close";
                        description = "When to offer to keep a context that has drifted from what was saved.";
                    };
                    notifications = lib.mkOption {
                        type = lib.types.bool;
                        default = true;
                        description = "Report launches, closes and drift to the notification daemon.";
                    };
                    show_search = lib.mkOption {
                        type = lib.types.bool;
                        default = true;
                        description = "Show the sidebar's search box.";
                    };
                    show_new_context = lib.mkOption {
                        type = lib.types.bool;
                        default = true;
                        description = "Show the row that starts a context.";
                    };
                    show_overview_button = lib.mkOption {
                        type = lib.types.bool;
                        default = true;
                        description = "Show the Overview button at the top of the sidebar.";
                    };
                    show_saved = lib.mkOption {
                        type = lib.types.bool;
                        default = true;
                        description = "Show saved contexts beneath the open ones.";
                    };
                    show_apps = lib.mkOption {
                        type = lib.types.bool;
                        default = true;
                        description = "Show matching applications under the search results.";
                    };
                    max_screens = lib.mkOption {
                        type = lib.types.ints.between 1 4;
                        default = 2;
                        description = "How many screen counts a context can hold a separate layout for.";
                    };
                    screen_order = lib.mkOption {
                        type = lib.types.listOf lib.types.str;
                        default = [ ];
                        example = [
                            "eDP-1"
                            "HDMI-A-1"
                        ];
                        description = ''
                            Which monitor is screen 1, screen 2, and so on. Empty means left to right.
                        '';
                    };
                    poll_seconds = lib.mkOption {
                        type = lib.types.ints.between 1 60;
                        default = 2;
                        description = "How often the open list is re-checked against the compositor.";
                    };
                    log_level = lib.mkOption {
                        type = lib.types.enum [
                            "debug"
                            "info"
                            "warning"
                            "error"
                            "critical"
                        ];
                        default = "info";
                        description = "How much detail Context writes to its log.";
                    };
                    backend = lib.mkOption {
                        type = lib.types.enum [
                            "auto"
                            "hyprland"
                            "none"
                        ];
                        default = "auto";
                        description = "Which window manager drives workspaces.";
                    };
                };
            };
            default = { };
            description = ''
                Context's settings.json. Written declaratively, so a change made on the settings screen does
                not survive a rebuild - what is set here wins.
            '';
        };

        contexts = lib.mkOption {
            type = lib.types.listOf contextType;
            default = [ ];
            description = ''
                Contexts to hand Context the first time it sees them. Each is taken in once and is an
                ordinary context from then on, so editing or forgetting one in the launcher is not undone at
                the next start.
            '';
        };

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
        # This session: the sidebar hides itself and comes back on hover, and the overview is the application
        # menu now that waybar has neither a menu nor a window list. mkDefault, so either can still be set
        # from elsewhere without fighting this.
        technet.context.settings = {
            collapse_mode = lib.mkDefault "hidden";
            auto_expand = lib.mkDefault true;
            # Chosen on the settings screen before this module existed. Declared here so the sidebar
            # stays as it was left - it is contexts and nothing else.
            show_search = lib.mkDefault false;
            show_saved = lib.mkDefault false;
            show_apps = lib.mkDefault false;
        };

        home-manager.users.beatlink = {
            # Context loads $XDG_CONFIG_HOME/context/style.css over its built-in stylesheet — the same
            # contract as waybar's style.css — so its look is declared here from the same palette as the rest
            # of the session. Only the accent-derived colours need spelling out; the translucent overlays
            # Context uses for cards and controls read correctly on any dark surface and are left to its
            # defaults.
            xdg.configFile."context/style.css".text = ''
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

            # Forced, because Context rewrites this file whenever a setting is changed on its own
            # settings screen: without it, the first such change leaves a real file where home-manager
            # expects its symlink and every later activation refuses to clobber it.
            xdg.configFile."context/settings.json" = {
                force = true;
                source = (pkgs.formats.json { }).generate "context-settings.json" cfg.settings;
            };

            xdg.configFile."context/contexts.json" = lib.mkIf (cfg.contexts != [ ]) {
                source = (pkgs.formats.json { }).generate "context-contexts.json" declared;
            };
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
    };
}
