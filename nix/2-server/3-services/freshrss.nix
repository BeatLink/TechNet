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
                    image = "freshrss/freshrss:alpine";
                    container_name = "freshrss";
                    hostname = "freshrss";
                    restart = "always";
                    volumes = [
                        "/Storage/Services/FreshRSS/data:/var/www/FreshRSS/data"
                        "/Storage/Services/FreshRSS/extensions:/var/www/FreshRSS/extensions"
                    ];

                    environment = {
                        TZ = "America/Jamaica";
                        CRON_MIN = "3,33";
                        TRUSTED_PROXY = "172.16.0.1/12 192.168.0.1/16";
                    };
                    healthcheck = {
                        test = [
                            "CMD"
                            "cli/health.php"
                        ];
                        timeout = "10s";
                        start_period = "60s";
                        interval = "75s";
                        retries = 3;
                    };
                    expose = [
                        "80"
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
                    ];
                    dns = [
                        "8.8.8.8"
                        "1.1.1.1"
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
