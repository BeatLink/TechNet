{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            packages = with pkgs; [ newsflash ];
            persistence."/Storage/Apps/Fun/NewsFlash" = {
                directories = [
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