{
    services.ollama = {
        enable = true;
        home = "/Storage/Apps/TechNet/Ollama/data";
        user = "ollama";
        group = "ollama";
        loadModels = [
            "gemma4:e2b"
        ];
        syncModels = true;
        acceleration = "cuda"; # enables GPU support
    };
}
