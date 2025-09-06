# Docker
#
# Almost all server services are provisioned with docker. These settings configure it.
#

{ pkgs, ... }:
{
    environment.systemPackages = with pkgs; [
        # Set packages installed on system
        arion
        docker-client
    ];
    virtualisation = {
        docker = {
            enable = true;
            liveRestore = false; # Solves hangs on shutdown
        };
        arion.backend = "docker";
    };
    environment.persistence."/Storage/System/Docker".directories = [ "/var/lib/docker" ];
    networking.firewall = {
        allowedTCPPorts = [
            80 # Nginx Services
            81 # Nginx Web Admin
            443 # Nginx Services (HTTPS)
            53 # Pihole DNS
            82 # Pihole Web Admin
        ];
        allowedUDPPorts = [
            53 # Pihole DNS
        ];
    };
    users.extraGroups.docker.members = [ "beatlink" ];
}
