{
    home-manager.users.beatlink  = { pkgs, ... }: {
        home.packages = with pkgs; [ pix ];
        dconf.enable = true;                                                        # Enables dconf for Pix Setting Management
        imports = [                                                                 # Imports Pix Dconf Settings
            ./2-dconf-settings.nix
        ];
    };
}