{
    services.ollama = {
        enable = true;
        acceleration = "cuda";
        home = "/Storage/Apps/AI/Ollama/data";
        user = "beatlink";
        group = "beatlink";
        loadModels = [
            "qwen3-coder:14b"
        ];
        syncModels = true;
    };
    users.users.beatlink.extraGroups = [
        "video"
        "render"
    ];
}
