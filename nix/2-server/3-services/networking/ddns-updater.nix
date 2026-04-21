{

    services.ddns-updater = {
        enable = true;
        environment = {
            SERVER_ENABLED = "yes";
            LISTENING_ADDRESS = "127.0.0.1:9420";
            RESOLVER_ADDRESS = "8.8.8.8:53"; 
        };
    };

    environment.persistence."/Storage/Services/DDNS".directories = [ "/var/lib/private/ddns-updater" ];

    nginx-vhosts.ddns = {
        domain = "ddns.heimdall.technet";
        port = 9420;
    };

}
