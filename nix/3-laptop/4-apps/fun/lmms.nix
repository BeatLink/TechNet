{ inputs, pkgs, ... }:
let
    halon = inputs.halon.packages.${pkgs.stdenv.hostPlatform.system};
    halonLmms = halon.halon-lmms-theme;
    halonQt = halon.halon-qt-theme;

    # LMMS replaces the application style sheet with its own but keeps the platform theme's
    # palette, and several of its widgets reset themselves to that palette where no style sheet
    # reaches them. Holding LMMS dark therefore means handing it its own qt5ct and qt6ct config.
    lmmsQtConfig = pkgs.runCommand "lmms-qt-config" { } ''
        for configurator in qt5ct qt6ct; do
            mkdir -p "$out/$configurator"
            cat > "$out/$configurator/$configurator.conf" <<EOF
        [Appearance]
        custom_palette=true
        color_scheme_path=${halonQt}/share/$configurator/colors/Halon-Dark.conf
        style=Fusion
        standard_dialogs=default

        [Interface]
        stylesheets=${halonQt}/share/halon/qt/Halon-Dark.qss
        EOF
        done
    '';

    # qt5ct reads its config from XDG_CONFIG_HOME with no per-application override, so the
    # wrapper mirrors the real config directory and shadows only the two configurator entries.
    lmms = pkgs.symlinkJoin {
        name = "lmms-halon";
        paths = [ pkgs.lmms ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
            wrapProgram $out/bin/lmms --run '
                halonConfig="''${XDG_RUNTIME_DIR:-/tmp}/lmms-halon-config"
                realConfig="''${XDG_CONFIG_HOME:-$HOME/.config}"
                rm -rf "$halonConfig"
                mkdir -p "$halonConfig"
                if [ -d "$realConfig" ]; then
                    find "$realConfig" -mindepth 1 -maxdepth 1 -exec ln -sfn {} "$halonConfig/" \;
                fi
                ln -sfn ${lmmsQtConfig}/qt5ct "$halonConfig/qt5ct"
                ln -sfn ${lmmsQtConfig}/qt6ct "$halonConfig/qt6ct"
                export XDG_CONFIG_HOME="$halonConfig"
            '
        '';
    };
in
{
    environment = {
        systemPackages = [ lmms ];

        # LMMS_THEME_PATH only reaches the style sheet; the artwork resolves against the theme
        # directory recorded in .lmmsrc.xml, which is why the theme also lives at a stable path
        sessionVariables.LMMS_THEME_PATH = "${halonLmms}/share/lmms/themes/Halon";

        # Nixos Impermanence is used instead of Home Manager impermanence as the latter does not allow bind mounts, only symlinks
        # LMMS does NOT like symlinks for its configuration file apparently.
        persistence."/Storage/Apps/Fun/LMMS" = {
            enable = true;
            hideMounts = true;
            users.beatlink = {
                files = [
                    ".lmmsrc.xml"
                ];
            };
        };
    };

    # LMMS rewrites .lmmsrc.xml wholesale, so the theme directory is set once by hand under
    # Edit -> Settings -> Paths and has to point somewhere that survives a rebuild
    home-manager.users.beatlink.xdg.dataFile."lmms/themes/Halon".source =
        "${halonLmms}/share/lmms/themes/Halon";
}
