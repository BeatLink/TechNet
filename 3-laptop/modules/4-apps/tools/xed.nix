{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ xed ];
            persistence."/Storage/Apps/Tools/Xed" = {
                directories = [
                    ".config/xed"
                ];
                allowOther = true;
            };
        };
    };
}

