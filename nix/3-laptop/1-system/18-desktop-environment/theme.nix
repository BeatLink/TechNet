# Desktop Theme
#
# One option choosing the look of the Hyprland session, and the palette every module reads instead of
# hard-coding colours. There is no such thing as "a Hyprland theme" to install — Hyprland has no theme
# format — so a look is assembled: a GTK theme for the applications, and the same handful of colours
# applied to the compositor chrome (borders, bar, lock screen, OSD, window bars) and to Context's
# launcher. Switching looks is changing `technet.theme.look` and rebuilding; only user services restart,
# so the session survives it.
#
# Cinnamon is deliberately not driven from here. Its appearance is dconf settings exported from the
# session, its look is Mint-Y by choice, and a GTK theme set through home-manager does not override its
# xsettings daemon anyway — so the option themes the Hyprland session and leaves Cinnamon alone.

{ config, lib, pkgs, ... }:
let
    # GTK3 consumers (waybar) reject 8-digit hex, so translucency there needs rgba() with decimal
    # channels. Every colour is therefore also published as an "r, g, b" triplet under palette.rgb.
    hexToDec = h: (builtins.fromTOML "v = 0x${h}").v;
    rgbOf = hex: lib.concatStringsSep ", " (map (i: toString (hexToDec (builtins.substring i 2 hex))) [ 0 2 4 ]);

    looks = {
        # Arc — the flat blue-grey look Budgie/Solus shipped by default. Assembled from the canonical
        # Arc-Dark palette; the GTK side is the maintained jnsh fork of arc-theme, with Papirus icons,
        # which is the pairing Arc desktops conventionally use.
        arc = {
            surface = "383c4a"; # window background
            card = "404552"; # raised surfaces
            border = "4b5162"; # dividers, inactive borders
            text = "d3dae3";
            accent = "5294e2"; # the Arc blue
            red = "e14245";
            yellow = "f8c146";
            gtk = {
                name = "Arc-Dark";
                package = pkgs.arc-theme;
            };
            icons = {
                name = "Papirus-Dark";
                package = pkgs.papirus-icon-theme;
            };
        };
        # Mint-Y with the aqua accent, matching Cinnamon — the default. nixpkgs' mint-themes tracks
        # Mint's releases, so this is whatever Mint currently ships as Mint-Y-Dark-Aqua.
        mint = {
            surface = "1e1e1e";
            card = "2a2a2a";
            border = "444444";
            text = "ffffff";
            accent = "5ac0c0"; # Mint-Y-Aqua
            red = "ff5555";
            yellow = "e5c07b";
            gtk = {
                name = "Mint-Y-Dark-Aqua";
                package = pkgs.mint-themes;
            };
            icons = {
                name = "Mint-Y-Aqua";
                package = pkgs.mint-y-icons;
            };
        };
        # Nord — kept as a third option so the enum is honestly an enum, and because its blue-grey is
        # close enough to Arc's to be a reasonable alternative with a softer accent.
        nord = {
            surface = "2e3440";
            card = "3b4252";
            border = "4c566a";
            text = "d8dee9";
            accent = "88c0d0";
            red = "bf616a";
            yellow = "ebcb8b";
            gtk = {
                name = "Nordic";
                package = pkgs.nordic;
            };
            icons = {
                name = "Papirus-Dark";
                package = pkgs.papirus-icon-theme;
            };
        };
    };
in
{
    options.technet.theme = {
        look = lib.mkOption {
            type = lib.types.enum (builtins.attrNames looks);
            default = "mint";
            description = "Which look the Hyprland session wears.";
        };
        palette = lib.mkOption {
            type = lib.types.attrs;
            readOnly = true;
            description = "The chosen look's colours (hex, no #) and theme packages, for modules to read.";
        };
    };

    config.technet.theme.palette =
        let
            chosen = looks.${config.technet.theme.look};
            colours = lib.filterAttrs (
                _: v: builtins.isString v && builtins.match "[0-9a-f]{6}" v != null
            ) chosen;
        in
        chosen // { rgb = lib.mapAttrs (_: rgbOf) colours; };
}
