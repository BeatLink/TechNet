# FreshRSS ##################################################################################################################################
#
# FreshRSS is the RSS Feed Manager
#
###########################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.freshrss = {
        serviceName = "freshrss";
        settings = {
            services = {
                freshrss.service = {
                    image = "freshrss/freshrss:latest";
                    container_name = "freshrss";
                    hostname = "freshrss";
                    restart = "always";
                    environment = {
                        "LISTEN" = "0.0.0.0:80";
                        "CRON_MIN" = "1,31";
                        "TZ" = "America/Jamaica";
                    };
                    volumes = [ 
                        "/Storage/Services/FreshRSS/data:/var/www/FreshRSS/data"
                        "/Storage/Services/FreshRSS/extensions:/var/www/FreshRSS/extensions"
                    ];
                    expose = [
                        "80"
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