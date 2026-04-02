{
    services.traccar = {
        enable = true;
        settings = {
            http.port = "8082";
            web.url = "traccar.heimdall.technet";
        };
    };
    environment.persistence."/Storage/Services/Traccar".directories = [ "/var/lib/private/traccar" ];
    nginx-vhosts.traccar = {
        domain = "traccar.heimdall.technet";
        port = 8082;
    };
}
