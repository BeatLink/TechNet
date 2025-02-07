{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ guake ];
            persistence."/Storage/Apps/Tools/Guake" = {
                directories = [
                ];
                allowOther = true;
            };
        };
    };
}

