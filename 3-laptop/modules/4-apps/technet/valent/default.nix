{
    networking.firewall = rec {
        allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
        allowedUDPPortRanges = allowedTCPPortRanges;
    };
    home-manager.users.beatlink = { pkgs, ... }: {
        imports = [                                                                 # Imports Pix Dconf Settings
            ./2-dconf-settings.nix
        ];
        services.kdeconnect = {
            enable = true;
            package = pkgs.valent;
        };
        home.persistence."/Storage/Apps/TechNet/Valent" = {
            directories = [
                ".cache/valent"
                ".config/valent"
            ];
            allowOther = true;
        };
    };
}