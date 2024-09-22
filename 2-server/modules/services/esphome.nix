{ config, lib, pkgs, modulesPath, ... }: 
{
    sops.age.sshKeyPaths = [ "/persistent/etc/ssh/ssh_host_ed25519_key" ];
    sops.secrets.esphome_password = {
        sopsFile = ../secrets/secrets.yaml;
    };
    virtualisation.arion.projects.esphome = {
        serviceName = "esphome";
        settings = {
            services = {
                esphome.service = {
                    image = "ghcr.io/esphome/esphome";
                    container_name = "esphome";
                    restart = "unless-stopped";
                    privileged = true;
                    volumes = [ 
                        "/Storage/Services/ESPHome/config:/config"
                        "/etc/localtime:/etc/localtime:ro"
                    ];
                    environment = {
                        "USERNAME" = "beatlink"
                        # The ESPHome Docker doesnt have an option for loading the password from a file. 
                        # This method wont keep the password outside of the store but at least it should be safe for github
                        "PASSWORD" = $(cat config.sops.secrets.esphome_password.path) 
                    };
                    expose = [
                        "80" 
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