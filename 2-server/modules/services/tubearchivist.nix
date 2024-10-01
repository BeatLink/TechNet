# TubeArchivist ###########################################################################################################################
#
# Youtube media center that manages YouTube videos, channels, subscriptions and watch history. 
#
###########################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.tubearchivist = {
        serviceName = "tubearchivist";
        settings = {
            services = {
                tubearchivist.service = {
                    image = "bbilly1/tubearchivist";
                    container_name = "tubearchivist";
                    hostname = "motioneye";
                    restart = "always";
                    volumes = [ 
                        "/Storage/Services/TubeArchivist/cache:/cache"
                        "/Storage/Files/Videos/TubeArchivist:/youtube"
                    ];
                    env_file = [
                        "/Storage/Services/TubeArchivist/.env"
                    ];
                    environment = {
                        "ES_URL" = "http://archivist-es:9200";
                        "REDIS_HOST" = "archivist-redis";
                        "HOST_UID" = "1000";
                        "HOST_GID" = "1000";
                        "TA_HOST" = "tubearchivist.heimdall.technet";
                        "TZ" = "America/Jamaica";
                    };
                    healthcheck = {
                        test = [
                            "CMD" "curl" "-f" "http://localhost:8000/health"
                        ];
                        interval = "2m";
                        timeout = "10s";
                        retries = 3;
                        start_period = "30s";
                    };
                    depends_on = [
                        "archivist-es"
                        "archivist-redis"
                    ];
                    expose = [
                        "8000"
                    ];
                    networks = [
                        "tubearchivist"
                        "nginx-proxy-manager_public"
                    ];
                };
                archivist-redis.service = {
                    image = "redis/redis-stack-server";
                    container_name = "archivist-redis";
                    restart = "always";
                    expose = [
                        "6379"
                    ];
                    volumes = [
                        "/Storage/Services/TubeArchivist/redis:/data"
                    ];
                    depends_on = [
                        "archivist-es"
                    ];
                    networks = [
                        "tubearchivist"
                    ];
                };
                archivist-es.service = {
                    image = "bbilly1/tubearchivist-es";
                    container_name = "archivist-es";
                    restart =  "always";
                    env_file = [
                        "/Storage/Services/TubeArchivist/.env"
                    ];
                    environment = {
                        "ES_JAVA_OPTS" = "-Xms1g -Xmx1g";
                        "xpack.security.enabled" = "true";
                        "discovery.type" = "single-node";
                        "path.repo" = "/usr/share/elasticsearch/data/snapshot";
                    };
                    volumes = [
                        "/Storage/Services/TubeArchivist/es:/usr/share/elasticsearch/data"
                    ];
                    expose = [
                        "9200"
                    ];
                    networks = [
                        "tubearchivist"
                    ];
                };
            };
            networks = {
                tubearchivist = {
                    driver = "bridge";
                };
                nginx-proxy-manager_public = {
                    external = true;
                };
            };
        };
    };
}