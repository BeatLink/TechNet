{ inputs, ... }:
{

    sops.secrets.freshrss_password = {
        sopsFile = "${inputs.self}/secrets/2-server.yaml";
    };
    virtualisation.arion.projects.freshrss = {
        serviceName = "freshrss";
        settings = {
            services = {
                freshrss.service = {
                    image = "freshrss/freshrss:latest";
                    container_name = "freshrss";
                    hostname = "freshrss";
                    restart = "always";
                    volumes = [
                        "/Storage/Services/FreshRSS/data:/data"
                        "/Storage/Services/FreshRSS/extensions:/extensions"
                    ];

                    environment = {
                        TZ = "America/Jamaica";
                        CRON_MIN = "3,33";
                        TRUSTED_PROXY = [
                            "172.16.0.1/12"
                            "192.168.0.1/16"
                        ];
                    };
                    healthcheck = {
                        test = [
                            "CMD"
                            "cli/health.php"
                        ];
                        timeout = "10s";
                        start_period = "60s";
                        start_interval = "11s";
                        interval = "75s";
                        retries = 3;
                    };
                    expose = [
                        "80"
                    ];
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
