#stacer
#gnome system monitor


{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ gnome-system-monitor ];
            persistence."/Storage/Apps/System/Gnome-System-Monitor" = {
                allowOther = true;
            };
        };
    };
}
