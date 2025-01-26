{ config, pkgs, ... }: 
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
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

