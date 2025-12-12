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
    systemd.services.docker-prune = {
        description = "Weekly Docker system prune";
        serviceConfig = {
            Type = "oneshot";
            ExecStart = [
                "${pkgs.docker}/bin/docker"
                "system"
                "prune"
                "-f"
                "-a"
                "--volumes"
            ];
        };
        # Make sure Docker is running before we prune
        after = [ "docker.service" ];
        wants = [ "docker.service" ];
    };

    systemd.timers.docker-prune = {
        description = "Weekly timer to prune Docker system";
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "Mon *-*-* 20:00:00"; # weekly Monday 8 PM (change day if needed)
            Persistent = true; # runs missed events after boot
        };
    };
}
