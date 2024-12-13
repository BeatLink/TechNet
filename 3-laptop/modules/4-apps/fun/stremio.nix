{ config, pkgs, ... }: 
{

    services.flatpak.packages = ["flathub:app/com.stremio.Stremio//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/Stremio" = {
                directories = [
                    ".var/app/com.stremio.Stremio"
                ];
                allowOther = true;
            };
            file = {
                ".config/plank/dock1/launchers/com.stremio.Stremio.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/com.stremio.Stremio.desktop
                '';
            };
        };
    };
}
