{
    virtualisation.arion.projects.uptime-kuma = {
        serviceName = "uptime-kuma";
        settings = {
            services = {
                uptime-kuma.service = {
                    image = "louislam/uptime-kuma:1";
                    container_name = "uptime-kuma";
                    restart = "always";
                    volumes = [ 
                        "/Storage/Services/Uptime-Kuma:/app/data"
                        "/var/run/docker.sock:/var/run/docker.sock"
                    ];
                    expose = [
                        "3001" 
                    ];
                    dns = [
                        "10.100.100.1"
                        "192.168.0.2"
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