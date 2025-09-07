{
    services.tang = {
        enable = true;
        ipAddressAllow = [
            "10.100.100.0/24"
        ];
        listenStream = [
            "10.100.100.2:7654"
        ];
    };
    systemd.services."tangd@" = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
            Restart = "always";
            RestartSec = "1s";
            StartLimitIntervalSec = 0;
        };
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
