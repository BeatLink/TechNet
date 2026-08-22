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

    looks = {
        # Mint-Y with the aqua accent — the default. nixpkgs' mint-themes tracks
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
    };
    halon = inputs.halon.packages.${pkgs.stdenv.hostPlatform.system}.halon-qt-theme;

    # Fusion is what the style sheet is written against; it assumes Fusion's element structure for everything it does not restyle.
    settings = qtct: ''
        [Appearance]
        custom_palette=true
        color_scheme_path=${halon}/share/${qtct}/colors/Halon.conf
        style=Fusion
        standard_dialogs=default

        [Interface]
        stylesheets=${halon}/share/halon/qt/Halon.qss
    '';

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

    qt = {
        enable = true;
        platformTheme = "qt5ct";
    };

    environment.systemPackages = [ halon ];

    home-manager.users.beatlink = {
        xdg.configFile = {
            "qt5ct/qt5ct.conf".text = settings "qt5ct";
            "qt6ct/qt6ct.conf".text = settings "qt6ct";
        };
    };
}
