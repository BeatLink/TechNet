{
    virtualisation.arion.projects.ddns-updater = {
        serviceName = "ddns-updater";
        settings = {
            services = {
                ddns-updater.service = {
                    image = "ghcr.io/qdm12/ddns-updater";
                    container_name = "ddns-updater";
                    restart = "always";
                    volumes = [
                        "/Storage/Services/DDNS/data:/updater/data"
                    ];
                    environment = {
                        "PERIOD" = "5m";
                        "UPDATE_COOLDOWN_PERIOD" = "5m";
                        "PUBLICIP_FETCHERS" = "all";
                        "PUBLICIP_HTTP_PROVIDERS" = "all";
                        "PUBLICIPV4_HTTP_PROVIDERS" = "all";
                        "PUBLICIPV6_HTTP_PROVIDERS" = "all";
                        "PUBLICIP_DNS_PROVIDERS" = "all";
                        "PUBLICIP_DNS_TIMEOUT" = "3s";
                        "HTTP_TIMEOUT" = "10s";

                        # Backup
                        "BACKUP_PERIOD" = "24h";
                        "BACKUP_DIRECTORY" = "/updater/data";

                        # Other
                        "LOG_LEVEL" = "info";
                        "LOG_CALLER" = "short";
                    };
                    expose = [
                        "8000"
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
                    ];
                };
            };
            networks = {
                nginx-proxy-manager_public = {
                    external = true;
                };
            };
        };
    };
}
