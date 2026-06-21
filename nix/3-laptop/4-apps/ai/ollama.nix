{pkgs, ...}:{
    services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        home = "/Storage/Services/AI/Ollama/data";
        user = "ollama";
        group = "ollama";
        loadModels = [
            "qwen3.5:4b"
        ];
        syncModels = true;
    };
    users.users.beatlink.extraGroups = [
        "video"
        "render"
    ];
}
