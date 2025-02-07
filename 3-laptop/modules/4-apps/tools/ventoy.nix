{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ ventoy-full ];
            persistence."/Storage/Apps/Tools/Ventoy" = {
                directories = [
                ];
                allowOther = true;
            };
        };
    };
}

