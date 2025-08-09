{
    networking.firewall = rec {
        allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
        allowedUDPPortRanges = allowedTCPPortRanges;
    };
    home-manager.users.beatlink = { pkgs, ... }: {
        services.kdeconnect = {
            enable = true;
        };
        home = {
            persistence."/Storage/Apps/TechNet/Valent" = {
                directories = [
                    ".cache/valent"
                    ".config/valent"
                ];
                allowOther = true;
            };
            file.".config/autostart/valent.desktop".source = "${pkgs.valent}/share/applications/ca.andyholmes.Valent.desktop";       # Configures plank to autostart on login

        };
        dconfImports.valent = {
            source = ./settings.dconf;
            path = "/ca/andyholmes/valent/";
        };        
    };
}