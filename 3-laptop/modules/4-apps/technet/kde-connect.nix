{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            file.".config/autostart/plank.desktop".source = "${pkgs.kdeconnect}/share/applications/org.kde.kdeconnect.daemon.desktop";       # Configures plank to autostart on login
            persistence."/Storage/Apps/TechNet/KDEConnect/" = {
                directories = [
                    ".config/kdeconnect/"
                ];
                allowOther = true;
            };
        };
    };
}
