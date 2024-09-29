# Glances ###############################################################################################################################
#
# Glances is a dashboard and system monitor. 
#
###########################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.glances = {
        serviceName = "glances";
        settings = {
            services = {
                glances.service = {
                    image = "nicolargo/glances:latest-full";
                    container_name = "glances";
                    hostname = "Heimdall";
                    restart = "always";
                    environment = {
                        "PUID" = "1000";
                        "PGID" = "1000";
                        "TZ" = "America/Jamaica";
                        "GLANCES_OPT" = "-w -C /glances/conf/glances.conf";
                    };
                    privileged = true;
                    volumes = [ 
                        "/Storage/Services/Glances/glances.conf:/glances/conf/glances.conf"
                        "/var/run/docker.sock:/var/run/docker.sock:ro"
                        "/etc/os-release:/etc/os-release:ro"
                        # Volumes to monitor
                        "/:/rootfs:ro"
                        "/Storage:/storagefs:ro"
                    ];
                    expose = [
                        "61208"
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