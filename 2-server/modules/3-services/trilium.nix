{
    virtualisation.arion.projects.trilium = {
        serviceName = "trilium";
        settings = {
            services = {
                trilium.service = {
                    image = "triliumnext/notes:latest";
                    container_name = "trilium";
                    restart = "always";
                    environment = {
                        "PUID" = "1000";
                        "PGID" = "1000";
                        "TZ" = "America/Jamaica";
                    };
                    volumes = [ 
                        "/Storage/Services/Trilium/data:/home/node/trilium-data"
                    ];
                    expose = [
                        "8081" 
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