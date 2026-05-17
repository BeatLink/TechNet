{pkgs, ...}:{
    services.ollama = {
        enable = true;
        home = "/Storage/Apps/TechNet/Ollama/data";
        user = "ollama";
        group = "ollama";
        package = pkgs.ollama-cuda;
        loadModels = [
            "gemma4:e2b"
        ];
        syncModels = true;
    };
}
