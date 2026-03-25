{
    networking.firewall = rec {
        allowedTCPPortRanges = [
            {
                from = 1714;
                to = 1764;
            }
        ];
        allowedUDPPortRanges = allowedTCPPortRanges;
    };
    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = [ pkgs.valent ];
                persistence."/Storage/Apps/TechNet/Valent" = {
                    directories = [
                        ".cache/valent"
                        ".config/valent"
                    ];

                };

            };
            dconfImports.valent = {
                source = ./settings.dconf;
                path = "/ca/andyholmes/valent/";
            };
            systemd.user.services.valent = {
                Unit = {
                    Description = "Valent - KDE Connect Implementation";
                    After = [ "graphical-session.target" ];
                    PartOf = [ "graphical-session.target" ];
                };

                Service = {
                    Type = "dbus";
                    BusName = "ca.andyholmes.Valent";
                    ExecStart = "${pkgs.valent}/bin/valent --gapplication-service";
                    Restart = "on-failure";
                    RestartSec = 5;
                };

                Install = {
                    WantedBy = [ "graphical-session.target" ];
                };
            };
        };
}
