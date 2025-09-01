{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ freetube ];
            persistence."/Storage/Apps/Fun/FreeTube" = {
                directories = [
                    ".config/FreeTube"
                ];
                allowOther = true;
            };
        };
    };
}

