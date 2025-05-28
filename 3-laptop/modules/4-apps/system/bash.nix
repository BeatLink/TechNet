{ config, pkgs, ... }: 
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/System/Bash" = {
                directories = [
                    ".local/share/bash"
                ];
                allowOther = true;
            };
        };
    };
}