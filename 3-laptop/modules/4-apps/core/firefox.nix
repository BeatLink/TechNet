{
    home-manager.users.beatlink = { config, lib, pkgs, ... }: {
        home = {
            packages = with pkgs; [ firefox ];
            persistence."/Storage/Apps/Core/Firefox" = {
                directories = [
                    ".cache/mozilla/firefox"
                    ".mozilla"
                ];
                allowOther = true;
            };
        };
    };
}