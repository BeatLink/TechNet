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
