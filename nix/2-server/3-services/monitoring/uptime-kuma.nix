{
    services.uptime-kuma = {
        enable = true;
        settings = {
            HOST = "127.0.0.1";
            PORT = "3001";
        };
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

    nginx-vhosts.uptime-kuma = {
        domain = "uptime-kuma.heimdall.technet";
        port = 3001;
    };
}
