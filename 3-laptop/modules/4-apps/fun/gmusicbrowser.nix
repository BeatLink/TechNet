{


    home-manager.users.beatlink = { config, pkgs, ... }: {
        services.flatpak = {
            packages = ["flathub:app/org.gmusicbrowser.gmusicbrowser//stable"];
            overrides."org.gmusicbrowser.gmusicbrowser" = {
                filesystems = [
                    "/Storage/Files/Music"
                ];
            };
        };
        home = {
            persistence."/Storage/Apps/Fun/Gmusicbrowser" = {
                directories = [
                    ".var/app/org.gmusicbrowser.gmusicbrowser"
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/org.gmusicbrowser.gmusicbrowser.desktop".source = config.lib.file.mkOutOfStoreSymlink "/var/lib/flatpak/exports/share/applications/org.gmusicbrowser.gmusicbrowser.desktop";
            };
        };
    };
}