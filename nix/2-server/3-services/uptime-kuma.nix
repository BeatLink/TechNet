{
    services.uptime-kuma = {
        enable = true;
        settings.host = "10.100.100.1";
    };
    networking.firewall.allowedTCPPorts = [ 3001 ];
    environment.persistence."/Storage/Services/Uptime-Kuma".directories = [
        "/var/lib/private/uptime-kuma"
    ];

    #users.users.uptime-kuma = {
    #    group = "uptime-kuma";
    #    extraGroups = [ "docker" ];
    #};
}
