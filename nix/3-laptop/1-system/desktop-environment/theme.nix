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
# session, its look is Halon by choice, and a GTK theme set through home-manager does not override its
# xsettings daemon anyway — so the option themes the Hyprland session and leaves Cinnamon alone.

{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
let
    # GTK3 consumers (waybar) reject 8-digit hex, so translucency there needs rgba() with decimal
    # channels. Every colour is therefore also published as an "r, g, b" triplet under palette.rgb.
    hexToDec = h: (builtins.fromTOML "v = 0x${h}").v;
    rgbOf =
        hex:
        lib.concatStringsSep ", " (
            map (i: toString (hexToDec (builtins.substring i 2 hex))) [
                0
                2
                4
            ]
        );

    # Halon publishes its tokens as JSON precisely so this file does not transcribe them
    token = name: lib.removePrefix "#" inputs.halon.tokens.light.${name};

    looks = {
        # Halon's light scheme — the default, and what every application wears. Cinnamon's
        # shell theme is deliberately the dark one, set in its own exported dconf; that is the
        # single dark surface in the session, the way a panel usually is.
        halon = {
            surface = token "surface-root";
            card = token "surface-default";
            border = token "border-default";
            text = token "text-body";
            accent = token "accent";
            red = token "status-danger";
            yellow = token "status-warning";
            gtk = {
                name = "Halon";
                package = inputs.halon.packages.${pkgs.stdenv.hostPlatform.system}.halon-theme;
            };
            # Halon ships no icon theme, so this is the set Cinnamon's exported dconf also names
            icons = {
                name = "Mint-Y-Aqua";
                package = pkgs.mint-y-icons;
            };
        };

        # Mint-Y with the aqua accent. nixpkgs' mint-themes tracks Mint's releases,
        # so this is whatever Mint currently ships as Mint-Y-Dark-Aqua.
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
    };
in
{
    options.technet.theme = {
        look = lib.mkOption {
            type = lib.types.enum (builtins.attrNames looks);
            default = "halon";
            description = "Which look the Hyprland session wears.";
        };
        palette = lib.mkOption {
            type = lib.types.attrs;
            readOnly = true;
            description = "The chosen look's colours (hex, no #) and theme packages, for modules to read.";
        };
    };

    config = {
        technet.theme.palette =
            let
                chosen = looks.${config.technet.theme.look};
                colours = lib.filterAttrs (
                    _: v: builtins.isString v && builtins.match "[0-9a-f]{6}" v != null
                ) chosen;
            in
            chosen // { rgb = lib.mapAttrs (_: rgbOf) colours; };

        # Selecting the platform theme is this machine's call; what Halon looks like through it is Halon's
        qt = {
            enable = true;
            platformTheme = "qt5ct";
        };
        home-manager.users.beatlink.themes.halon = {
            qt = true;
            qtScheme = "light";
        };
    };

}
