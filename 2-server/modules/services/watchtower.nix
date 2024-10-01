{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.watchtower = {
        serviceName = "watchtower";
        settings = {
            services = {
                watchtower.service = {
                    image = "containrrr/watchtower";
                    container_name = "watchtower";
                    restart = "always";
                    volumes = [ 
                      "/var/run/docker.sock:/var/run/docker.sock"
                    ];    
                    env_file = [
                      "/Storage/Services/Watchtower/.env"
                    ];
                    command = [
                      "--interval" "1800"  "--http-api-update" "--http-api-periodic-polls" "--http-api-metrics"
                    ];
                    expose = [
                      "8080"
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