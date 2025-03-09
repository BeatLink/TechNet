{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages =  [ pkgs.ventoy-full.override { 
                withGtk3 = true;
            } ];
            persistence."/Storage/Apps/Tools/Ventoy" = {
                directories = [
                ];
                allowOther = true;
            };
        };
    };
}

