{    
    home-manager.users.beatlink = { config, pkgs, ... }: {

        home = {
            packages = with pkgs; [ (callPackage ./gmusicbrowser.nix {}) ];
            persistence."/Storage/Apps/Fun/Gmusicbrowser" = {
                directories = [
                    ".config/gmusicbrowser"
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/org.gmusicbrowser.gmusicbrowser.desktop".source = config.lib.file.mkOutOfStoreSymlink "/home/beatlink/.nix-profile/share/applications/gmusicbrowser.desktop";
            };
        };
    };
}