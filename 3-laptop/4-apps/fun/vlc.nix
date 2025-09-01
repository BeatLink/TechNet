{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages = with pkgs; [ vlc ];
            persistence."/Storage/Apps/Fun/VLC" = {
                directories = [
                    ".cache/vlc"
                    ".config/vlc"
                    ".local/share/vlc"
                ];
                allowOther = true;
            };
        };
    };
}