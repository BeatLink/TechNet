{
    services.tang = {
        enable = true;
        ipAddressAllow = [ "10.100.100.0/24" ];
        listenStream = [ "10.100.100.2:7654" ];
    };
    networking.firewall.allowedTCPPorts = [ 7654 ];
    environment.persistence."/persistent" = {
        directories = [
            "/var/db/tang"
            "/var/lib/private/tang"
        ];
    };
}
