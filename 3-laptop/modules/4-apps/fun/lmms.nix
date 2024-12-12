{ config, pkgs, ... }: 
{

    services.flatpak = {
        preSwitchCommand = ''flatpak override --persist=.lmmsrc.xml io.lmms.LMMS'';
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
                allowOther = true;
            };
        };
    };
}