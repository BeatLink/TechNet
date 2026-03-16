{
    services.uptime-kuma = {
        enable = true;
        port = 3001;
        dataDir = "/Storage/Services/Uptime-Kuma";
    };
    networking.firewall.allowedTCPPorts = [ 3001 ];
    users.users.uptime-kuma.extraGroups = [ "docker" ];
}
