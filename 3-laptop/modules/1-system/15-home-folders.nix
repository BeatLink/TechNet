{ config, pkgs, ... }: 
{
        
    home-manager.users.beatlink = { config, pkgs, ... }: {
        xdg.userDirs =  {
            enable = true;
            desktop = "/Storage/Files/Desktop";
            documents = "/Storage/Files/Documents";
            download = "/Storage/Files/Downloads";
            music = "/Storage/Files/Music";
            pictures = "/Storage/Files/Pictures";
            videos = "/Storage/Files/Videos";
        };
    };
}

