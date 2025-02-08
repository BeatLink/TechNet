{lib, ...}: 
{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ alarm-clock-applet ];
            persistence."/Storage/Apps/Tools/Alarm-Clock-Applet" = {
                allowOther = true;
            };
        };
        xdg.autoStart.desktopItems = {
            alarm-clock-applet = pkgs.makeDesktopItem {
                name = "alarm-clock-applet";
                desktopName = "alarm-clock-applet";
                exec = "alarm-clock-applet --hidden";
            };
        };
        imports = [ ./2-dconf-settings.nix ];
    };
}

