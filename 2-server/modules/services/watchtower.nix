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
                };
            };
        };
    };
}