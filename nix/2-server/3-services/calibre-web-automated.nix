# Calibre Web Automated
#
# Used for eBook viewing and management.
#
# https://github.com/crocodilestick/Calibre-Web-Automated
# 

{
    virtualisation.arion.projects.calibre-web-automated = {
        serviceName = "calibre-web-automated";
        settings = {
            services = {
                calibre-web.service = {
                    image = "crocodilestick/calibre-web-automated:latest";
                    container_name = "calibre-web-automated";
                    restart = "always";
                    environment = {
                        "PUID" = "1000";
                        "PGID" = "1000";
                        "TZ" = "America/Jamaica";
                    };
                    volumes = [ 
                        "/Storage/Services/Calibre-Web/config:/config"
                        "/Storage/Services/Calibre-Web/Uploads:/cwa-book-ingest"
                        "/Storage/Files/eBooks/Calibre/Library:/calibre-library"
                    ];
                    expose = [
                        "8083"
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