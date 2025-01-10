{ config, pkgs, ... }: 
{

    services.flatpak.packages = ["flathub:app/io.gitlab.news_flash.NewsFlash//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/NewsFlash" = {
                directories = [
                    ".var/app/io.gitlab.news_flash.NewsFlash"
                ];
                allowOther = true;
            };
        };
    };
}