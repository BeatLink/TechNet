{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages =  [ pkgs.ventoy-full-gtk ];
            persistence."/Storage/Apps/Tools/Ventoy" = {
                directories = [
                ];
                allowOther = true;
            };
        };
    };
}

