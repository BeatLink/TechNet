{
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ guake ];
            persistence."/Storage/Apps/Tools/Guake" = {
                directories = [
                ];
                allowOther = true;
            };
            file = {
                ".config/autostart/guake.desktop".source = "${pkgs.guake}/share/applications/guake.desktop";
            };
        };
        imports = [                                                                 # Imports Pix Dconf Settings
            ./2-dconf-settings.nix
        ];
    };
}

