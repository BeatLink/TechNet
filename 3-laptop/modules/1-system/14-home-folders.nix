{ config, pkgs, ... }: 
{
        
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.persistence."/Storage/Files" = {
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
        };
    };
}

