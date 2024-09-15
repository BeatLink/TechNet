
{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion = {
        backend = "docker";
        projects.blockurl = {
            serviceName = "blockurl";
            settings = {
                services = {
                    blockurl = {
                        image = "mariadb:latest";
                        container_name = "blockurl"
                        restart = "unless-stopped"
                        volumes = [ 
                            "/Storage/Services/BlockURL/database:/app/database"
                        ];
                        expose = [
                            "80" 
                        ];
                        networks = [
                            "nginx_public"
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
    };
}