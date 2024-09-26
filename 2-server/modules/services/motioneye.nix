# MotionEye ###############################################################################################################################
#
# MotionEye is a video recorder used with homeassistant for my security system. 
#
###########################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.motioneye = {
        serviceName = "motioneye";
        settings = {
            services = {
                motioneye.service = {
                    image = "ccrisan/motioneye:master-amd64";
                    container_name = "motioneye";
                    hostname = "motioneye";
                    restart = "unless-stopped";
                    devices = [
                        "/dev/video0:/dev/video0"
                        "/dev/dri:/dev/dri"
                    ];
                    volumes = [ 
                        "/etc/localtime:/etc/localtime:ro"
                        "/Storage/Services/MotionEye/etc:/etc/motioneye"
                        "/Storage/Services/MotionEye/data:/var/lib/motioneye"
                    ];
                    expose = [
                        "8765"
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