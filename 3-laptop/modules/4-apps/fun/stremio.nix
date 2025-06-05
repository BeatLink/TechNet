{

    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ stremio ];
            persistence."/Storage/Apps/Fun/Stremio" = {
                directories = [
                    ".cache/Smart Code ltd"
                    ".config/Smart Code ltd"
                    ".local/share/Smart Code ltd"
                    ".stremio-server"
                ];
                allowOther = true;
            };
        };
    };
}
