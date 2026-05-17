{
    services.open-webui = {
        enable = true;
        port = 9770;
    };

    environment.persistence."/Storage/Services/Open-WebUI/data".directories = [
        "/var/lib/private/open-webui"
    ];

    nginx-vhosts.open-webui = {
        domain = "ai.heimdall.technet";
        port = 9770;
    };
}
