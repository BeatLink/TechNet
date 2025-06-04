{    home-manager.users.beatlink = { config, pkgs, ... }: {

        home = {
            packages = with pkgs; [ callPackage(./gmusicbrowser.nix) ];
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