{ config, pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ kdePackages.kclock ];
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        {
            home.persistence."/Storage/Apps/Tools/KClock" = {
                files = [ ".config/kclockdrc" ];

            };
        };
}
