{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/com.discordapp.Discord//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.persistence."/Storage/Apps/Comms/Discord" = {
            directories = [
                ".var/app/com.discordapp.Discord"
            ];
            allowOther = true;
        };
    };
}

