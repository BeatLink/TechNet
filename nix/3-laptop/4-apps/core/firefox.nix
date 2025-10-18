{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ firefox ];
            persistence."/Storage/Apps/Core/Firefox" = {
                directories = [
                    ".cache/mozilla/firefox"
                    ".mozilla/firefox"
                ];
                allowOther = true;
            };
        };
    };
}