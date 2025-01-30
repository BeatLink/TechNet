{ config, pkgs, ... }: 
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages = with pkgs; [ thunderbird ];
            persistence."/Storage/Apps/Comms/Thunderbird" = {
                directories = [
                    ".cache/thunderbird"
                    ".thunderbird"
                ];
                allowOther = true;
            };
        };
    };
}