{
    nginx-vhosts.homepage = {
        domain = "homepage.heimdall.technet";
        port = 9011;
    };
    virtualisation.arion.projects.homepage = {
        serviceName = "homepage";
        settings = {
            services = {
                homepage.service = {
                    image = "ghcr.io/gethomepage/homepage:latest";
                    container_name = "homepage";
                    restart = "always";
                    volumes = [
                        "/Storage/Services/Homepage/config:/app/config"
                        "/var/run/docker.sock:/var/run/docker.sock"
                    ];
                    ports = [
                        "9011:3000"
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
                    ];
                    extra_hosts = [
                        "host.docker.internal:host-gateway"
                    ];
                    environment = {
                        "HOMEPAGE_ALLOWED_HOSTS" = "www.heimdall.technet,heimdall.technet,homepage.heimdall.technet";
                    };
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
