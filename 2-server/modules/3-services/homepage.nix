{ config, lib, pkgs, modulesPath, ... }: 
{
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
                    expose = [
                        "3000" 
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
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
