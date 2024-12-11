{ config, lib, pkgs, ... }:
{
    services.flatpak.packages = ["flathub:app/org.mozilla.firefox//stable"];

    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.persistence."/Storage/Apps/Core/Firefox".directories = [ ".var/app/org.mozilla.firefox" ];
    };
}