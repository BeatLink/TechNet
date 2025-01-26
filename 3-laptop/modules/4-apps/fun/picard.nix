{
    home-manager.users.beatlink = { config, lib, pkgs, ... }: {
        home = {
            packages = with pkgs; [ picard ];
            persistence."/Storage/Apps/Core/Picard" = {
                directories = [
                    ".cache/MusicBrainz"
                    ".config/MusicBrainz"
                ];
                allowOther = true;
            };
        };
    };
}