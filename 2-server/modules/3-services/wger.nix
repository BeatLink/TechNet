{ config, ... }: {
    sops.secrets.wger_env = {
        sopsFile = ../../secrets.yaml;
    };
    virtualisation.arion.projects.wger = {
        serviceName = "wger";
        settings = {
            services = {
                web.service = {
                    image = "wger/server:latest";
                    restart = "always";
                    depends_on = {
                        db = {
                            condition = "service_healthy";
                        };
                        cache = {
                            condition = "service_healthy";
                        };
                    };
                    healthcheck = {
                        test = ["CMD-SHELL" "wget --no-verbose --tries=1 --spider http://localhost:8000"];
                        interval = "10s";
                        timeout = "5s";
                        start_period = "300s";
                        retries = 5;
                    }; 
                    env_file = [
                        config.sops.secrets.wger_env.path
                    ];
                    volumes = [ 
                        "/Storage/Services/Wger/static:/home/wger/static"
                        "/Storage/Services/Wger/media:/home/wger/media"
                    ];
                    networks = [
                        "wger"
                    ];
                    expose = [
                        "8000" 
                    ];
                };      
                wger-nginx.service = {
                    image = "nginx:stable";
                    restart = "always";
                    depends_on = {
                        web = {};
                    };
                    healthcheck = {
                        test = ["CMD-SHELL" "service nginx status"];
                        interval = "10s";
                        timeout = "5s";
                        start_period = "30s";
                        retries = 5;
                    };              
                    env_file = [
                        config.sops.secrets.wger_env.path
                    ];
                    volumes = [ 
                        "/Storage/Services/Wger/config/nginx.conf:/etc/nginx/conf.d/default.conf"
                        "/Storage/Services/Wger/static:/wger/static:ro"
                        "/Storage/Services/Wger/media:/wger/media:ro"
                    ];
                    expose = [
                        "80" 
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
                        "wger"
                    ];
                };
                db.service = {
                    image = "postgres:15-alpine";
                    restart = "always";
                    healthcheck = {
                        test = ["CMD-SHELL" "pg_isready -U wger"];
                        interval = "10s";
                        timeout = "5s";
                        start_period = "30s";
                        retries = 5;
                    };              
                    env_file = [
                        config.sops.secrets.wger_env.path
                    ];
                    volumes = [ 
                        "/Storage/Services/Wger/postgres-data:/var/lib/postgresql/data/"
                    ];
                    networks = [
                        "wger"
                    ];
                    expose = [
                        "5432" 
                    ];
                };
                cache.service = {
                    image = "redis";
                    command = ["redis-server" "/usr/local/etc/redis/redis.conf"];
                    restart = "always";
                    healthcheck = {
                        test = ["CMD-SHELL" "redis-cli ping"];
                        interval = "10s";
                        timeout = "5s";
                        start_period = "30s";
                        retries = 5;
                    };
                    env_file = [
                        config.sops.secrets.wger_env.path
                    ];
                    volumes = [ 
                        "/Storage/Services/Wger/config/redis.conf:/usr/local/etc/redis/redis.conf"
                        "/Storage/Services/Wger/redis-data:/data"
                    ];
                    networks = [
                        "wger"
                    ];
                    expose = [
                        "6379" 
                    ];
                };
                celery_worker.service = {
                    image = "wger/server:latest";
                    command = ["/start-worker"];
                    restart = "always";
                    depends_on = {
                        web = {
                            condition = "service_healthy";
                        };
                    };
                    healthcheck = {
                        test = ["CMD-SHELL" "celery -A wger inspect ping"];
                        interval = "10s";
                        timeout = "5s";
                        start_period = "30s";
                        retries = 5;
                    };              
                    env_file = [
                        config.sops.secrets.wger_env.path
                    ];
                    volumes = [ 
                        "/Storage/Services/Wger/media:/home/wger/media"
                    ];
                    networks = [
                        "wger"
                    ];

                };  
                celery_beat.service = {
                    image = "wger/server:latest";
                    command = ["/start-beat"];
                    restart = "always";
                    depends_on = {
                        celery_worker = {
                            condition = "service_healthy";
                        };
                    };           
                    env_file = [
                        config.sops.secrets.wger_env.path
                    ];
                    volumes = [ 
                        "/Storage/Services/Wger/celery-beat:/home/wger/beat/"
                    ];
                    networks = [
                        "wger"
                    ];

                }; 
            };
            networks = {
                nginx-proxy-manager_public = {
                    external = true;
                };
                wger = {
                    driver = "bridge";
                };
            };
        };
    };
}
