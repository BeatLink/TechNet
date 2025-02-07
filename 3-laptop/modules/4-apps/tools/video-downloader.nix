{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ video-downloader ];
            persistence."/Storage/Apps/Tools/Video-Downloader" = {
                directories = [
                ];
                allowOther = true;
            };
        };
    };
}

