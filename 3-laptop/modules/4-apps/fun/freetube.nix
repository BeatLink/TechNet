{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/io.freetubeapp.FreeTube//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/FreeTube" = {
                directories = [
                    ".var/app/io.freetubeapp.FreeTube"
                ];
                allowOther = true;
            };
        };
    };
}

