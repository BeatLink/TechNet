{ inputs, pkgs, ... }:
let
    halonLmms = inputs.halon.packages.${pkgs.stdenv.hostPlatform.system}.halon-lmms-theme;
in
{
    environment = {
        systemPackages = [ pkgs.lmms ];

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
