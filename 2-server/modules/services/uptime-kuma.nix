{ config, lib, pkgs, modulesPath, ... }: 
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
                    ];
                    expose = [
                        "3001" 
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