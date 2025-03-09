{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages =  [ (pkgs.ventoy-full.override { defaultGuiType = "gtk3"; }) ];
            persistence."/Storage/Apps/Tools/Ventoy" = {
                directories = [
                ];
                allowOther = true;
            };
        };
    };
}

