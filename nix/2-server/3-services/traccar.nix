{
    services.traccar = {
        enable = true;
        settings = {
            web = {
                port = "9280";
                url = "traccar.heimdall.technet";
            };
        };
    };
    environment.persistence."/Storage/Services/Traccar".directories = [ "/var/lib/private/traccar" ];
    nginx-vhosts.traccar = {
        domain = "traccar.heimdall.technet";
        port = 9280;
    };
}
