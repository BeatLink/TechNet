
{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/org.videolan.VLC//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/VLC" = {
                directories = [
                    ".var/app/org.videolan.VLC"
                ];
                allowOther = true;
            };
        };
    };
}