{ config, pkgs, ... }: 
{

    services.flatpak = {
        preSwitchCommand = ''flatpak override --persist="." io.lmms.LMMS'';
        packages = ["flathub:app/io.lmms.LMMS//stable"];
        overrides."io.lmms.LMMS" = {
            filesystems = [
                "/Storage/Files/Sounds"
            ];
        };
    };
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/LMMS" = {
                directories = [
                    ".var/app/io.lmms.LMMS"
                ];
                files = [
                    ".lmmsrc.xml"
                ];
                allowOther = true;
            };
            file = {
                ".config/plank/dock1/launchers/io.lmms.LMMS.dockitem".text = ''
                    [PlankDockItemPreferences]
                    Launcher=file:///var/lib/flatpak/exports/share/applications/io.lmms.LMMS.desktop
                '';
            };
        };
    };
}