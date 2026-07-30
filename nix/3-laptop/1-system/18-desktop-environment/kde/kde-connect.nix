{
    config,
    lib,
    pkgs,
    ...
}:
{
    programs.kdeconnect.enable = true;
    home-manager.users.beatlink =
        { config, pkgs, ... }:
        {
            home = {
                file.".config/autostart/kdeconnectd.desktop".source =
                    "${pkgs.plasma5Packages.kdeconnect-kde}/share/applications/org.kde.kdeconnect.daemon.desktop"; # Configures plank to autostart on login
                persistence."/Storage/Apps/TechNet/KDEConnect/" = {
                    directories = [
                        ".config/kdeconnect/"
                    ];

                };
            };
        };
}
