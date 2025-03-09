{
    virtualisation.arion.projects.traccar = {
        serviceName = "traccar";
        settings = {
            services = {
                traccar.service = {
                    image = "traccar/traccar:latest";
                    container_name = "traccar";
                    restart = "always";
                    volumes = [ 
                        "/Storage/Services/Traccar/logs:/opt/traccar/logs:rw"
                        "/Storage/Services/Traccar/traccar.xml:/opt/traccar/conf/traccar.xml:ro"
                        "/Storage/Services/Traccar/data:/opt/traccar/data:rw"
                    ];
                    environment = {
                        "PUID" = "1000";
                        "PGID" = "1000";
                        "APP_BASE_URL" = "traccar.heimdall.technet";
                    };
                    expose = [
                        "8082" 
                    ];
                    ports = [
                      "5013:5013"
                      "5013:5013/udp"
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