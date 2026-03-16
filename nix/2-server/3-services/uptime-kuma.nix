{
    services.uptime-kuma = {
        enable = true;
        settings.HOST = "10.100.100.1";
    };
    networking.firewall.allowedTCPPorts = [ 3001 ];
    environment.persistence."/Storage/Services/Uptime-Kuma".directories = [
        {
            directory = "/var/lib/private/uptime-kuma";
            mode = "0700";
        }
    ];

    #users.users.uptime-kuma = {
    #    group = "uptime-kuma";
    #    extraGroups = [ "docker" ];
    #};
}
