{ inputs, ... }:
{
    virtualisation.arion.projects.whatsupdocker = {
        serviceName = "whatsupdocker";
        settings = {
            services = {
                freshrss.service = {
                    image = "getwud/wud";
                    container_name = "whatsupdocker";
                    restart = "always";
                    volumes = [
                        "/var/run/docker.sock:/var/run/docker.sock"
                        "/Storage/Services/WhatsUpDocker/store:/store"
                    ];

                    environment = {
                        TZ = "America/Jamaica";
                        WUD_TRIGGER_DOCKER_Local_PRUNE = "true";
                        WUD_AUTH_BASIC_BEATLINK_USER = "beatlink";
                        WUD_AUTH_BASIC_JOHN_HASH = "beatlink:$$apr1$$3qiufh2y$$lf3lOZHYcWh1A.D.3wCgj/";
                    };
                    healthcheck = {                        
                        test = [
                            "CMD-SHELL"
                            "curl --fail http://localhost:\${WUD_SERVER_PORT:-3000}/health || exit 1"
                        ];
                        timeout = "10s";
                        start_period = "10s";
                        interval = "10s";
                        retries = 3;
                    };
                    expose = [
                        "3000"
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

