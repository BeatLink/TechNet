{ inputs, ... }:
{
    sops.secrets.esphome_password = {
        sopsFile = "${inputs.self}/secrets/2-server.yaml";
    };
    virtualisation.arion.projects.esphome = {
        serviceName = "esphome";
        settings = {
            services = {
                esphome.service = {
                    image = "ghcr.io/esphome/esphome";
                    container_name = "esphome";
                    restart = "always";
                    privileged = true;
                    volumes = [
                        "/Storage/Services/ESPHome/config:/config"
                        "/etc/localtime:/etc/localtime:ro"
                    ];
                    environment = {
                        "USERNAME" = "beatlink";
                        # The ESPHome Docker doesnt have an option for loading the password from a file.
                        # This method wont keep the password outside of the store but at least it should be safe for github
                        #"PASSWORD" = (builtins.readFile config.sops.secrets.esphome_password.path);
                        "ESPHOME_DASHBOARD_USE_PING" = "true";
                    };
                    ports = [
                        "6052:6052"
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

    nginx-vhosts.esphome = {
        domain = "esphome.heimdall.technet";
        port = 6052;
    };
}
