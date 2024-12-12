{ config, pkgs, ... }: 
{

    services.flatpak = {
        packages = ["flathub:app/io.lmms.LMMS//stable"];
        overrides."io.lmms.LMMS" = {
            filesystems = [
                "/Storage/Files/Sounds"
            ];
            persist = [
                ".lmmsrc.xml"
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