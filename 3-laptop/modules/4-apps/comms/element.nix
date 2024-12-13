{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/im.riot.Riot//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Comms/Element" = {
                directories = [
                    ".var/app/im.riot.Riot"
                ];
                allowOther = true;
            };
            file = {
                ".config/plank/dock1/launchers/im.riot.Riot.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/im.riot.Riot.desktop
                '';
            };
        };
    };
}

