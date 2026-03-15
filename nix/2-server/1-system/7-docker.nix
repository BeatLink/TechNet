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
        lazydocker
    ];
    virtualisation = {
        docker = {
            enable = true;
            liveRestore = false; # Solves hangs on shutdown
            autoPrune = {
                enable = true;
                flags = [
                    "--all"
                    "--volumes"
                ];
            };
            # Override the default Docker daemon configuration
            daemon.settings = {
                # Set default shm size to 2GB (in bytes)
                # Default is 64MB (67108864 bytes)
                "default-shm-size" = "2g";
            };
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
