{
    services.open-webui = {
        enable = true;
        port = 9552;
    };

    environment.persistence."/Storage/Services/Ollama/open-webui".directories = [
        "/var/lib/open-webui"
    ];

    nginx-vhosts.open-webui = {
        domain = "open-webui.heimdall.technet";
        port = 9552;
    };
}
