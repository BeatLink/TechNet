{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ gnome-decoder ];
            persistence."/Storage/Apps/Tools/Decoder" = {
                directories = [];
                allowOther = true;
            };
        };
    };
}

