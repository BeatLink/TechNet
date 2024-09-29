# Calibre #################################################################################################################################
#
# Calibre and Calibre Web are used for eBook viewing and management.
#
# https://hub.docker.com/r/linuxserver/calibre-web
# https://github.com/janeczku/calibre-web
# https://academy.pointtosource.com/containers/ebooks-calibre-readarr/
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.calibre = {
        serviceName = "calibre";
        settings = {
            services = {
                calibre-web.service = {
                    image = "linuxserver/calibre-web:latest";
                    container_name = "calibre-web";
                    restart = "always";
                    environment = {
                        "PUID" = "1000";
                        "PGID" = "1000";
                        "TZ" = "America/Jamaica";
                    };
                    volumes = [ 
                        "/Storage/Services/Calibre/Calibre-Web-Config:/config"
                        "/Storage/Files/eBooks/Calibre/Library:/Calibre_Library"
                    ];
                    expose = [
                        "8083"
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