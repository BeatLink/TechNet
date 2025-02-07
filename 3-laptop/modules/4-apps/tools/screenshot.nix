{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ gnome-screenshot ];
            persistence."/Storage/Apps/Tools/Screenshot" = {
                directories = [];
                allowOther = true;
            };
        };
    };
}

