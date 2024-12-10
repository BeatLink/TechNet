{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/im.riot.Riot//stable"];
    home.persistence."/Storage/Apps/Comms/Element" = {
        directories = [
            ".var"
        ];
    };
}

