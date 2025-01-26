{

    services.flatpak = {
        packages = ["flathub:app/ch.x29a.playitslowly//stable"];
        overrides."ch.x29a.playitslowly" = {
            filesystems = [
                "/Storage/Files/Music"
            ];
        };
    };
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/PlayItSlowly" = {
                directories = [
                    ".var/app/ch.x29a.playitslowly"
                ];
                allowOther = true;
            };
        };
    };
}