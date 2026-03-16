{
    services.uptime-kuma = {
        enable = true;
        settings.HOST = "10.100.100.1";
    };
    systemd.services.uptime-kuma.serviceConfig = {
        SupplementaryGroups = [ "docker" ];
    };
    environment.persistence."/Storage/Services/Uptime-Kuma".directories = [
        {
            directory = "/var/lib/private/uptime-kuma";
            mode = "0700";
        }
    ];
    networking.firewall.allowedTCPPorts = [ 3001 ];
}
