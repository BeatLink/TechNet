{ config, lib, pkgs, ... }:
{
    services.flatpak.packages = ["flathub:app/org.mozilla.firefox//stable"];

    programs.fuse.userAllowOther = true;
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home.persistence."/Storage/Apps/Core/Firefox" = {
            directories = [
                ".var/app/org.mozilla.firefox"
            ];
            allowOther = true;
        };
    };

    # Migrate Profiles

    
}