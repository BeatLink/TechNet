{ config, pkgs, ... }: 
{
    environment.persistence."/Storage/Apps/Fun/LMMS" = {
        enable = true;
        hideMounts = true;
        users.beatlink = {
            files = [
                ".lmmsrc.xml"
            ];
        };
    };

    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages = with pkgs; [ lmms ];
        };
    };
}