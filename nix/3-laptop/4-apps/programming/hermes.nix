{ config, ... }: {
    sops.secrets.hermes_env = {
        sopsFile = "${config.technet.secrets.path}/hermes.yaml";
        owner = "beatlink";
    };
    services.hermes-agent = {
        enable = true;
        container.enable = false;
        addToSystemPackages = true;
        stateDir = "/Storage/Apps/AI/Hermes";
        environmentFiles = [ config.sops.secrets."hermes_env".path ];
        settings = {
            model = {
                default = "lmstudio-community/lfm2-24b-a2b-gguf";
            };
            terminal = {
                backend = "local";
                timeout = 180;
            };
            memory = {
                enabled = true;
            };
        };
    };
}
