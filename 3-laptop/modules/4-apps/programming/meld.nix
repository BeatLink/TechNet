{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ meld ];
            persistence."/Storage/Apps/Programming/Meld" = {
                directories = [
                    ".local/share/meld"                    
                ];
                allowOther = true;
            };
        };
    };
}
