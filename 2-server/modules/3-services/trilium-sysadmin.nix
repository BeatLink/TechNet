{
    virtualisation.arion.projects.trilium-sysadmin = {
        serviceName = "trilium-sysadmin";
        settings = {
            services = {
                trilium.service = {
                    image = "triliumnext/notes:v0.93.0";
                    container_name = "trilium-sysadmin";
                    restart = "always";
                    environment = {
                        "PUID" = "1000";
                        "PGID" = "1000";
                        "TZ" = "America/Jamaica";
                    };
                    volumes = [ 
                        "/Storage/Services/Trilium-Sysadmin/data:/home/node/trilium-data"
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