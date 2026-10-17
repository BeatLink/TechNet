{ config, ... }: {
    # 2. Ollama Local Backend Service with CUDA Acceleration
    services.ollama = {
        enable = true;
        acceleration = "cuda";
        # Listen locally so Hermes can talk to it securely
        host = "127.0.0.1";
        port = 11434;
    };

    # ── 3. Hermes Agent Service Configuration ──────────────────
    services.hermes-agent = {

        enable = true;

        environmentFiles = [ config.sops.secrets."hermes-env".path ];

        # Expose 'hermes' command globally in user terminal paths
        addToSystemPackages = true;

        # Container-aware isolation settings (optional, keeps workspace clean)
        container.enable = false;

        # Declarative Hermes Settings (mapped directly to its underlying config)
        settings = {
            model = {
                # Point Hermes to your locally running Ollama model provider
                default = "ollama/lfm2.5-24b-a2b";
            };

            terminal = {
                backend = "local";
                timeout = 180;
            };

            memory = {
                enabled = true;
            };
        };

        # Workspace persona documents injected declaratively
        documents = {
            "SOUL.md" = ''
                You are Hermes, a sharp, pragmatic local AI personal assistant running on a Lenovo IdeaPad Gaming 3.
                You optimize for local hardware limitations (RTX 3050 Ti with offloading to 32GB RAM) and concise, direct help.
            '';
            "USER.md" = ''
                Name: Developer
                Environment: NixOS, Local LLM via Ollama
            '';
        };
    };
}
