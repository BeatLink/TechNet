{
    services.ddns-updater = {
        enable = true;
        environment = {
            SERVER_ENABLED="no";
            CONFIG_FILEPATH = "/Storage/Apps/System/DDNS/config.json";
            PERIOD = "5m";
        };
    };
}