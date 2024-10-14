# Mealie ##################################################################################################################################
#
# Mealie is my recipe and meal planning manager
#
###########################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: 
{
    sops.secrets.mealie_env.sopsFile = ../../secrets.yaml;
    virtualisation.arion.projects.mealie = {
        serviceName = "mealie";
        settings = {
            services = {
                mealie.service = {
                    image = "ghcr.io/mealie-recipes/mealie:v1.3.2";
                    container_name = "mealie";
                    restart = "always";
                    depends_on = [
                      "mealie-postgres"
                    ];
                    env_file = [
                      config.sops.secrets.mealie_env.path
                    ];
                    environment = {
                        "ALLOW_SIGNUP" = "true";
                        "PUID" = "1000";
                        "PGID" = "1000";
                        "TZ" = "America/Jamaica";
                        "MAX_WORKERS" = "1";
                        "WEB_CONCURRENCY" = "1";
                        "BASE_URL" = "https://mealie.heimdall.technet";
                        "DB_ENGINE" = "postgres";
                        "POSTGRES_USER" = "mealie";
                        "POSTGRES_SERVER" = "mealie-postgres";
                        "POSTGRES_PORT" = "5432";
                        "POSTGRES_DB" = "mealie";

                    };
                    volumes = [ 
                        "/Storage/Services/Mealie/mealie-data:/app/data/"
                    ];
                    expose = [
                        "9000"
                    ];
                    networks = [
                        "mealie"
                        "nginx-proxy-manager_public"
                    ];
                };
                mealie-postgres.service = {
                    container_name = "mealie-postgres";
                    image = "postgres:15";
                    restart = "always";
                    volumes = [ 
                        "/Storage/Services/Mealie//mealie-pgdata:/var/lib/postgresql/data"
                    ];
                    env_file = [
                      "/Storage/Services/Mealie/.env"
                    ];
                    environment = {
                        "POSTGRES_USER" = "mealie";
                    };
                    networks = [
                        "mealie"
                    ];
                };
                
            };
            networks = {
                mealie = {
                    driver = "bridge";
                };
                nginx-proxy-manager_public = {
                    external = true;
                };
            };
        };
    };
}