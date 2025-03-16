# Home Assistant ##########################################################################################################################
# Home Assistant is the home automation server. It manages lighting and energy management, safety and security.
###########################################################################################################################################


{
    virtualisation.arion.projects.home-assistant = {
        serviceName = "home-assistant";
        settings = {
            services = {
                home-assistant.service = {
                    image = "ghcr.io/home-assistant/home-assistant:2025.3.2";
                    container_name = "home-assistant";
                    restart = "always";
                    devices = [
                        "/dev/video0:/dev/video0"
                        "/dev/dri:/dev/dri"
                    ];
                    volumes = [ 
                        "/Storage/Services/Homeassistant/config:/config"
                        "/Storage/Services/Homeassistant/media:/media"
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