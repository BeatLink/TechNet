{
    services.tang = {
        enable = true;
        ipAddressAllow = [
            "10.100.100.0/24"
            "192.168.0.0/24"
        ];
        listenStream = [
            "0.0.0.0:7654"
        ];
    };
    networking.firewall.allowedTCPPorts = [ 7654 ];
    environment.persistence."/Storage/Apps/System/Tang" = {
        directories = [
            {
                directory = "/var/db/tang";
                mode = "0700";
            }
            {
                directory = "/var/lib/private/tang";
                mode = "0700";
            }
        ];
    };
}
