{
    services.uptime-kuma.enable = true;
    networking.firewall.allowedTCPPorts = [ 3001 ];
    environment.persistence."/Storage/Services/Uptime-Kuma".directories = [
        "/var/lib/private/uptime-kuma"
    ];

    #users.users.uptime-kuma = {
    #    group = "uptime-kuma";
    #    extraGroups = [ "docker" ];
    #};
}
