{ pkgs, ... }:
{
    services.ollama = {
        enable = true;
        home = "/Storage/Apps/TechNet/Ollama/data";
        user = "ollama";
        group = "ollama";
        host = "10.100.100.2";
        package = pkgs.ollama-cuda;
        loadModels = [
            "gemma4:e2b"
        ];
        syncModels = true;
    };
}
