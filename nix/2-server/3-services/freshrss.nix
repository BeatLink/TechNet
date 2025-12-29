{ inputs, ... }:
{
    # README: Feed updates will fail if IPV6 is disabled on the host system. This can be solved by setting the following
    #   ./data/config.php
    #         'curl_options' => array (
    #               CURLOPT_DNS_SERVERS => '8.8.8.8,1.1.1.1',
    #               CURLOPT_IPRESOLVE => CURL_IPRESOLVE_V4,
    #           ),
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
                        BASE_URL = "https://freshrss.heimdall.technet";
                        SERVER_DNS = "freshrss.heimdall.technet";
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
