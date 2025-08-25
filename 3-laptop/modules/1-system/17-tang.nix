{
    services.tang = {
        enable = true;
        ipAddressAllow = [
            "10.100.100.0/24"
            "192.168.0.0/24"
        ];
        listenStream = [
            "10.100.100.2:7654"
            "192.168.0.3:7654"
        ];
    };
    systemd.sockets.tangd = {
        wants = [
            "network-online.target"
            "NetworkManager.service"
        ];
        after = [
            "network-online.target"
            "NetworkManager.service"
        ];
    };
    networking.firewall.allowedTCPPorts = [ 7654 ];
    environment.persistence."/persistent" = {
        directories = [
            {
                directory = "/var/db/tang";
                mode = "0700";
            }
            {
                directory = "/var/lib/private";
                mode = "0700";
            }
        ];
    };
}
