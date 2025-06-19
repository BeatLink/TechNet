{
    virtualisation.arion.projects.trilium = {
        serviceName = "trilium-sysadmin";
        settings = {
            services = {
                trilium.service = {
                    image = "triliumnext/notes:latest";
                    container_name = "trilium-sysadmin";
                    restart = "always";
                    volumes = [ 
                        "/Storage/Services/TriliumSysadmin/data:/home/node/trilium-data"
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