{ config, pkgs, ... }: 
{
        
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.persistence."/Storage/Files" = {
            directories = [
                "Backups"
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

