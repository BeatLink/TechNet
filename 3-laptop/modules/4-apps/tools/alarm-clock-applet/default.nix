{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ alarm-clock-applet ];
            persistence."/Storage/Apps/Tools/Alarm-Clock-Applet" = {
                allowOther = true;
            };
            file = {
                ".config/autostart/alarm-clock-applet.desktop".source = "${pkgs.alarm-clock-applet}/share/applications/alarm-clock-applet.desktop";
            };
        };
        imports = [ ./2-dconf-settings.nix ];
    };
}

