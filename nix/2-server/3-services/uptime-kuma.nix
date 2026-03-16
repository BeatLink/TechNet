{
    services.uptime-kuma = {
        enable = true;
        settings = {
            DATA_DIR = "/Storage/Services/Uptime-Kuma";
            PORT = 3001;
        };
    };
    networking.firewall.allowedTCPPorts = [ 3001 ];
    users.users.uptime-kuma = {
        group = "uptime-kuma";
        extraGroups = [ "docker" ];
    };
}
