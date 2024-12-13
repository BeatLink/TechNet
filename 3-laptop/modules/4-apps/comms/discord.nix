{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/com.discordapp.Discord//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Comms/Discord" = {
                directories = [
                    ".var/app/com.discordapp.Discord"
                ];
                allowOther = true;
            };
            file = {
                ".config/plank/dock1/launchers/com.discordapp.Discord.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/com.discordapp.Discord.desktop
                '';
            };
        };
    };
}

