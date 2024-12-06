# Syncthing ###############################################################################################################################
#
# SyncThing is the main file synchronization system across all devices in the TechNet. By keeping files on multiple redundant devices it 
# also acts as a first line backup mechanism
# 
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{

    virtualisation.arion.projects.syncthing = {
        serviceName = "syncthing";
        settings = {
            services = {
                syncthing.service = {
                    image = "syncthing/syncthing:latest";
                    container_name = "syncthing";
                    hostname = "Heimdall";
                    restart = "always";
                    volumes = [ 
                        "/Storage/Services/Syncthing:/var/syncthing"
                        "/Storage/Files:/Files"
                    ];
                    environment = {
                        "PUID" = "1000";
                        "PGID" = "1000";
                        "APP_BASE_URL" = "syncthing.heimdall.technet";
                    };
                    expose = [
                        "8384" 
                    ];
                    ports = [
                      "22000:22000/tcp"  # TCP file transfers
                      "22000:22000/udp"  # QUIC file transfers
                      "21027:21027/udp"  # Receive local discovery broadcasts
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