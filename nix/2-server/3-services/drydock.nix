{ inputs, config, ... }:
{
    sops.secrets.drydock_env = {
        sopsFile = "${inputs.self}/secrets/2-server.yaml";
        restartUnits = [ "drydock.service" ];
    };
    virtualisation.arion.projects.drydock = {
        serviceName = "drydock";
        settings = {
            services = {
                freshrss.service = {
                    image = "codeswhat/drydock:latest";
                    container_name = "drydock";
                    hostname = "drydock";
                    restart = "always";
                    volumes = [
                        "/var/run/docker.sock:/var/run/docker.sock"
                        "/Storage/Services/DryDock/store:/store"
                    ];
                    env_file = [
                        config.sops.secrets.drydock_env.path
                    ];
                    environment = {
                        TZ = "America/Jamaica";
                        DD_AUTH_BASIC_ADMIN_USER = "admin";
                        DD_WATCHER_LOCAL_CRON = "*/5 * * * *";
                    };
                    healthcheck = {
                        test = [
                            "CMD-SHELL"
                            "curl --fail http://localhost:3000 || exit 1"
                        ];
                        timeout = "10s";
                        start_period = "10s";
                        interval = "10s";
                        retries = 3;
                    };
                    expose = [
                        "3000"
                    ];
                    dns = [
                        "1.1.1.1"
                        "8.8.8.8"
                    ]; # <-- add this
                    networks = [
                        "nginx-proxy-manager_public"
                    ];
                };
            };
            networks = {
                nginx-proxy-manager_public = {
                    external = true;
                };
            };
        };
    };
}
