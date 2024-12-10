{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/im.riot.Riot//stable"];
    programs.fuse.userAllowOther = true;

    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.persistence."/Storage/Apps/Comms/Element" = {
            directories = [
                ".var/app/im.riot.Riot"
            ];
            allowOther = true;
        };
    };
}

