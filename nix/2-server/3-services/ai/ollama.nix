{
    services.ollama = {
        enable = true;
        home = "/Storage/Services/Ollama/data";
        user = "ollama";
        group = "ollama";
        loadModels = [
            "gemma3:1b"
            "gemma4:e2b"
        ];
        syncModels = true;
    };
}
