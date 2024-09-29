# Deluge ##################################################################################################################################
#
# Deluge is the torrent management server. The torrent server allows for automatic 24/7 downloading and setting of content. 
#
# https://hub.docker.com/r/linuxserver/deluge
#
###########################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.deluge = {
        serviceName = "deluge";
        settings = {
            services = {
                deluge.service = {
                    image = "linuxserver/deluge:latest";
                    container_name = "deluge";
                    restart = "always";
                    environment = {
                        "PUID" = "1000";
                        "PGID" = "1000";
                        "TZ" = "America/Jamaica";
                    };
                    volumes = [ 
                        "/Storage/Services/Deluge/config:/config"
                        "/Storage/Files/Downloads:/downloads"
                    ];
                    expose = [
                        "8112"
                    ];
                    ports = [
                        "58846:58846"
                        "6881:6881"
                        "6881:6881/udp"
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