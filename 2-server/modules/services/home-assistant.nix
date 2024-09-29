# Home Assistant ##########################################################################################################################
# Home Assistant is the home automation server. It manages lighting and energy management, safety and security.
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.home-assistant = {
        serviceName = "home-assistant";
        settings = {
            services = {
                home-assistant.service = {
                    image = "home-assistant/home-assistant:latest";
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
                        "nginx_public"
                    ];
                    ports = [
                        "9170:9170"
                        "1900:1900"
                        "5353:5353"
                    ];
                };
            };
            networks = {
                nginx_public = {
                    external = true;
                };
            };
        };
    };
}