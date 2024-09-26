# https://hub.docker.com/repository/docker/beatlink/blockurl
# https://github.com/BeatLink/BlockURL

{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.dashy = {
        serviceName = "dashy";
        settings = {
            services = {
                dashy.service = {
                    image = "lissy93/dashy:latest";
                    container_name = "dashy";
                    restart = "unless-stopped";
                    volumes = [ 
                        "/Storage/Services/Dashy/config.yaml:/app/user-data/conf.yml"
                        "/Storage/Services/Dashy/icons:/app/public/item-icons"
                    ];
                    expose = [
                        "8080" 
                    ];
                    networks = [
                        "nginx_public"
                    ];
                    extra_hosts = [
                        "host.docker.internal:host-gateway"
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






# System info

# HDD Storage
# Network Connectivity and Speed
# Docker container health
# Uptime
# Neofetch
# Processes

# uptime kuma