{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ element-desktop ];
            persistence."/Storage/Apps/Comms/Element" = {
                directories = [
                    ".config/Element"
                ];
                allowOther = true;
            };
        };
    };
}

