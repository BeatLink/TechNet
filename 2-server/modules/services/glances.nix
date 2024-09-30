# Glances ###############################################################################################################################
#
# Glances is a dashboard and system monitor. 
#
###########################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: 
{
    networking.firewall.allowedTCPPorts = [ 61208 ]; 
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
                    network_mode =  "host";
                    volumes = [ 
                        "/Storage/Services/Glances/glances.conf:/glances/conf/glances.conf"
                        "/var/run/docker.sock:/var/run/docker.sock:ro"
                        "/etc/os-release:/etc/os-release:ro"
                        # Volumes to monitor
                        "/:/rootfs:ro"
                        "/Storage:/storagefs:ro"
                    ];

                };
                glances-proxy.service ={
                    image = "alpine/socat:1.0.3";
                    entrypoint = "/bin/sh";
                    container_name = "glances-proxy";
                    command = [
                        "-c" 
                        "ip -4 route list match 0/0 | awk '{print $$3\" host.docker.internal\"}' >> /etc/hosts && socat tcp-listen:61208,fork,reuseaddr tcp-connect:host.docker.internal:61208"
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