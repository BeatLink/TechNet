{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages =  with pkgs; [ lmms ];
        };
    };

    # Nixos Impermanence is used instead of Home Manager impermanence as the latter does not allow bind mounts, only symlinks
    # LMMS does NOT like symlinks for its configuration file apparently.
    environment = {
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
}