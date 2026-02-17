{
    services.ddns-updater = {
        enable = true;
        environment = {
            SERVER_ENABLED="no";
            CONFIG_FILEPATH = "/Storage/Services/DDNS/config.json";
            PERIOD = "5m";
        };
    };
    environment.persistence."/Storage/System/DDNS/data".directories = [ "/var/lib/private/ddns-updater" ];
}