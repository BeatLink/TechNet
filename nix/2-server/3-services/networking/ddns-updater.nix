{

    services.ddns-updater = {
        enable = true;
        environment = {
            SERVER_ENABLED = "yes";
            CONFIG_FILEPATH = "/Storage/Services/DDNS/config.json";
            PERIOD = "5m";
            LISTENING_ADDRESS = "9420";
        };
    };
    nginx-vhosts.ddns = {
        domain = "ddns.heimdall.technet";
        port = 9420;
    };

}
