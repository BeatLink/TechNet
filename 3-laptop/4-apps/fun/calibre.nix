{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages = with pkgs; [ calibre ];
            persistence."/Storage/Apps/Fun/Calibre" = {
                directories = [
                    ".cache/calibre"
                    ".config/calibre"
                ];
                allowOther = true;
            };
        };
    };
}

