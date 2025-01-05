{ config, pkgs, ... }: 
{
    environment.systemPackages = with pkgs; [ audacious ];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/Audacious" = {
                directories = [
                ];
                allowOther = true;
            };
        };
    };
}

