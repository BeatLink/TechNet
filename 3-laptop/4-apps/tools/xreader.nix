{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ xreader];
            persistence."/Storage/Apps/Tools/XReader" = {
                directories = [
                    ".config/xreader"
                ];
                allowOther = true;
            };
        };
    };
}

