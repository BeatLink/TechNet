{ config, pkgs, ... }: 
{
        
    home-manager.users.beatlink = { config, pkgs, ... }: {
        xdg.userDirs =  {
            enable = true;
            desktop = "/Storage/Files/Desktop";
            documents = "/Storage/Files/Documents";
            download = "/Storage/Files/Download";
            music = "/Storage/Files/Music";
            pictures = "/Storage/Files/Pictures";
            videos = "/Storage/Files/Videos";
        };
        /*home.persistence."/Storage/Files" = {                         # Disabled: Unable to hide mounts
            directories = [
                "Backups"
                "Desktop"
                "Documents"
                "Downloads"
                "eBooks"
                "Games"
                "Music"
                "Pictures"
                "Projects"
                "Sounds"
                "Videos"
                "VMs"
            ];
            allowOther = true;
        };*/
    };
}

