{ pkgs, ... }:
{
    services.ollama = {
        enable = true;
        user = "ollama";
        group = "ollama";
        home = "/Storage/Services/Ollama/data";
        loadModels = [
            #"dolphin3"
            #"gemma3"
            #"gemma3:27b"
            "deepseek-r1:latest"
            #"deepseek-r1:1.5b"
        ];
        syncModels = true;
    };

    services.open-webui = {
        enable = true;
        port = 9770;
    };
    environment.persistence."/Storage/Services/Ollama/open-webui".directories = [
        "/var/lib/private/open-webui"
    ];

    nginx-vhosts.ollama = {
        domain = "ollama.heimdall.technet";
        port = 9770;
    };
}
