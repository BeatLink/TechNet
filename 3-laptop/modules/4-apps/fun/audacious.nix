{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages =  with pkgs; [ audacious ];
            persistence."/Storage/Apps/Fun/Audacious" = {
                directories = [
                    ".config/audacious"
                ];
                allowOther = true;
            };
        };
    };
}

