{ config, pkgs, ... }: 
{
    environment.systemPackages = with pkgs; [ calibre ];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/Calibre" = {
                directories = [
                    ".cache/calibre"
                    ".config/calibre"
                ];
                allowOther = true;
            };
        };
    };
}

