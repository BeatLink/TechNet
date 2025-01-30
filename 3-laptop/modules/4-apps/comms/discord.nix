{ config, pkgs, ... }: 
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages = with pkgs; [ discord ];
            persistence."/Storage/Apps/Comms/Discord" = {
                directories = [
                    ".config/discord"
                ];
                allowOther = true;
            };
        };
    };
}

