# https://hub.docker.com/r/linuxserver/calibre-web
# https://github.com/janeczku/calibre-web
# https://academy.pointtosource.com/containers/ebooks-calibre-readarr/

{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.calibre = {
        serviceName = "calibre";
        settings = {
            services = {
                calibre.service = {
                    image = "linuxserver/calibre:latest";
                    container_name = "calibre";
                    restart = "unless-stopped";
                    environment = {
                        "PUID" = "1000"
                        "PGID" = "1000"
                        "TZ" = "America/Jamaica"
                    }
                    volumes = [ 
                        "/Storage/Services/Calibre/Config:/config"
                        "/Storage/Services/Calibre/Uploads:/uploads"
                        "/Storage/Services/Calibre/Plugins:/plugins"
                        "/Storage/Files/eBooks/Calibre/Library:/Calibre_Library"
                    ];
                    expose = [
                        "8080"
                        "8081"
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
}