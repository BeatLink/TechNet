{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ gnome-clocks ];
            persistence."/Storage/Apps/Tools/Clocks" = {
                directories = [];
                allowOther = true;
            };
        };
    };
}

