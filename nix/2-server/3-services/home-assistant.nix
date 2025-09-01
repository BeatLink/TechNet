# Home Assistant
# 
# Home Assistant is the home automation server. It manages lighting and energy management, safety and security.
#


{
    virtualisation.arion.projects.home-assistant = {
        serviceName = "home-assistant";
        settings = {
            services = {
                home-assistant.service = {
                    image = "ghcr.io/home-assistant/home-assistant:stable";
                    container_name = "home-assistant";
                    restart = "always";
                    volumes = [ 
                        "/Storage/Services/Homeassistant/config:/config"
                        "/Storage/Services/Homeassistant/media:/media"
                        "/Storage/Files/Music:/music"
                        "/Storage/Files/Sounds:/sounds"
                    ];
                    environment = {
                        "TZ" = "America/Jamaica";
                    };
                    expose = [
                        "8123" 
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
                    ];
                    ports = [
                        "9170:9170"
                        "1900:1900"
                        "5353:5353"
                    ];
                    extra_hosts = [
                        "host.docker.internal:host-gateway"
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