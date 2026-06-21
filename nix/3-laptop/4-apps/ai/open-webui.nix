{
    services.open-webui = {
        enable = true;
        port = 9770;
    };
    environment.persistence."/Storage/Apps/AI/Open-WebUI/data".directories = [
        "/var/lib/private/open-webui"
    ];
    services.open-webui.environment = {
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434/api";
    };
}
