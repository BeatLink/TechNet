{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.trilium = {
        serviceName = "trilium";
        settings = {
            services = {
                trilium.service = {
                    image = "triliumnext/notes:latest";
                    container_name = "trilium";
                    restart = "always";
                    volumes = [ 
                        "/Storage/Services/Trilium/data:/home/node/trilium-data"
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