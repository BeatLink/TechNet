{ config, pkgs, ... }: 
{
    services.flatpak = {
        packages = ["flathub:app/com.valvesoftware.Steam//stable"];
        overrides."com.valvesoftware.Steam" = {
            filesystems = [ ];
        };
    };
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/Steam" = {
                directories = [
                    ".var/app/com.valvesoftware.Steam"
                    #".steam"
                ];
                allowOther = true;
            };
        };
    };
}

