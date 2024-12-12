{ config, pkgs, ... }: 
{

    services.flatpak.packages = ["flathub:app/org.gmusicbrowser.gmusicbrowser//stable"];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Fun/Gmusicbrowser" = {
                directories = [
                    ".var/app/org.gmusicbrowser.gmusicbrowser"
                ];
                allowOther = true;
            };
            file.".config/autostart/org.gmusicbrowser.gmusicbrowser.desktop".source = config.lib.file.mkOutOfStoreSymlink "/var/lib/flatpak/app/org.gmusicbrowser.gmusicbrowser/current/active/files/share/applications/org.gmusicbrowser.gmusicbrowser.desktop";
        };
    };
}