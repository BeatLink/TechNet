{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ drawio ];
            persistence."/Storage/Apps/Tools/Drawio" = {
                directories = [
                    ".config/draw.io"
                ];
                allowOther = true;
            };
        };
    };
}

