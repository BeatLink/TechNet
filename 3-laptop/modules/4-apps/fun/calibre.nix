{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/com.calibre_ebook.calibre//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/Calibre" = {
                directories = [
                    ".var/app/com.calibre_ebook.calibre"
                ];
                allowOther = true;
            };
            file = {
                ".config/plank/dock1/launchers/com.calibre_ebook.calibre.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/com.calibre_ebook.calibre.desktop
                '';
            };
        };
    };
}

