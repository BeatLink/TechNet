{
    services.ollama = {
        enable = true;
        home = "/Storage/Services/Ollama/Data";
        loadModels = [
            "gemma3:1b"
            "gemma4:e2b"
        ];
        syncModels = true;
    };
}
