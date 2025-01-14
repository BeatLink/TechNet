{ config, pkgs, ... }: 
{

    services.flatpak.packages = ["flathub:app/io.gitlab.news_flash.NewsFlash//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages = with pkgs; [ newsflash ];
            persistence."/Storage/Apps/Fun/NewsFlash" = {
                directories = [
                    ".var/app/io.gitlab.news_flash.NewsFlash"
                    ".cache/news_flash"
                    ".config/news-flash"
                    ".local/share/news_flash"
                    ".local/share/news-flash"
                ];
                allowOther = true;
            };
        };
    };
}