{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/io.freetubeapp.FreeTube//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/FreeTube" = {
                directories = [
                    ".var/app/io.freetubeapp.FreeTube"
                ];
                allowOther = true;
            };
            file = {
                ".config/plank/dock1/launchers/io.freetubeapp.FreeTube.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/io.freetubeapp.FreeTube.desktop
                '';
            };
        };
    };
}

