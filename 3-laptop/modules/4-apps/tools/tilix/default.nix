{pkgs, ...}:{
    services.xserver.excludePackages = [ pkgs.xterm ];
    home-manager.users.beatlink = { pkgs, ... }: {
        home = {
            packages = with pkgs; [ tilix ];
            persistence."/Storage/Apps/Tools/Tilix" = {
                directories = [
                ];
                allowOther = true;
            };
        };
        imports = [                                                                 # Imports Pix Dconf Settings
            ./2-dconf-settings.nix
        ];
    };
}

