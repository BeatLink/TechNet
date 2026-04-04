# Home Assistant
#
# Home Assistant is the home automation server. It manages lighting and energy management, safety and security.
#

{
    services.home-assistant = {
        # opt-out from declarative configuration management
        config = null;
        lovelaceConfig = null;
        # configure the path to your config directory
        configDir = "/etc/home-assistant";
        # specify list of components required by your configuration
        extraComponents = [
            "esphome"
            "met"
            "radio_browser"
        ];
    };

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
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
                    ];
                    ports = [
                        "8124:8123"
                        "9171:9170"
                        "1901:1900"
                        "5354:5353"
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
    nginx-vhosts.home-assistant-new = {
        domain = "home-assistant-new.heimdall.technet";
        port = 8123;
    };

    nginx-vhosts.home-assistant = {
        domain = "home-assistant.heimdall.technet";
        port = 8124;
    };
}
