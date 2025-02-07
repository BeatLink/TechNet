{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ alarm-clock-applet ];
            persistence."/Storage/Apps/Tools/Alarm-Clock-Applet" = {
                directories = [
                ];
                allowOther = true;
            };
        };
    };
}

