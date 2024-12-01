{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/im.riot.Riot//stable"];
}

