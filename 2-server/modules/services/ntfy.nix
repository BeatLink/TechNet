# Ntfy.sh #################################################################################################################################
# Ntfy.sh is the notification manager for the TechNet.
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.ntfy = {
        serviceName = "ntfy";
        settings = {
            services = {
                ntfy.service = {
                    image = "binwiederhier/ntfy";
                    container_name = "ntfy";
                    restart = "always";
                    command = [
                      "serve"
                    ];
                    volumes = [ 
                        "/Storage/Services/Ntfy/cache:/var/cache/ntfy"
                        "/Storage/Services/Ntfy/etc:/etc/ntfy"
                    ];
                    environment = {
                        "TZ" = "America/Jamaica";
                    };
                    expose = [
                        "80" 
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
                    ];
                    healthcheck = {
                      test = [
                        "CMD-SHELL"
                        "wget -q --tries=1 http://localhost:80/v1/health -O - | grep -Eo '\"healthy\"\\s*:\\s*true' || exit 1"
                      ];
                      interval = "60s";
                      timeout = "10s";
                      retries = 3;
                      start_period = "40s";
                    };
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