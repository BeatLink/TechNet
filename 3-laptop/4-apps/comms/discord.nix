{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ discord ];
            persistence."/Storage/Apps/Comms/Discord" = {
                directories = [
                    ".config/discord"
                ];
                allowOther = true;
            };
        };
    };
}

