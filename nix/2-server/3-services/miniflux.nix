# RSS Feed Manager
#

{ inputs, config, ... }:
{
    sops.secrets.miniflux_env.sopsFile = "${inputs.self}/secrets/2-server.yaml";

    virtualisation.arion.projects.miniflux = {
        serviceName = "miniflux";
        settings = {
            services = {
                miniflux.service = {
                    image = "miniflux/miniflux:latest";
                    container_name = "miniflux";
                    restart = "always";
                    env_file = [
                        config.sops.secrets.miniflux_env.path
                    ];
                    environment = {
                        "TZ" = "America/Jamaica";
                    };
                    expose = [
                        "8080"
                    ];
                    networks = [
                        "miniflux"
                        "nginx-proxy-manager_public"
                    ];
                    dns = [
                        "8.8.8.8"
                        "1.1.1.1"
                    ];
                    depends_on = {
                        miniflux-db = {
                            condition = "service_healthy";
                        };
                    };
                };
                miniflux-db.service = {
                    image = "postgres:17-alpine";
                    container_name = "miniflux-db";
                    restart = "always";
                    env_file = [
                        config.sops.secrets.miniflux_env.path
                    ];
                    volumes = [
                        "/Storage/Services/Miniflux/miniflux-db:/var/lib/postgresql/data"
                    ];
                    networks = [
                        "miniflux"
                    ];
                    healthcheck = {
                        test = [
                            "CMD"
                            "pg_isready"
                            "-U"
                            "miniflux"
                        ];
                        interval = "10s";
                        start_period = "30s";
                    };
                };
            };
            networks = {
                nginx-proxy-manager_public = {
                    external = true;
                };
                miniflux = {
                    driver = "bridge";
                };
            };
        };
    };
}
