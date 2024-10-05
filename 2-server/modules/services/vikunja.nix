{ config, lib, pkgs, modulesPath, ... }: 
{
    virtualisation.arion.projects.vikunja = {
        serviceName = "vikunja";
        settings = {
            services = {
                vikunja.service = {
                    image = "vikunja/vikunja";
                    container_name = "vikunja";
                    restart = "always";
                    depends_on = {
                      db = {
                        condition = "service_healthy";
                      };
                    };
                    env_file = [
                      "/Storage/Services/Vikunja/.env"
                    ];
                    environment = {
                      "VIKUNJA_SERVICE_PUBLICURL" = "https://vikunja.heimdall.technet";
                      "VIKUNJA_DATABASE_HOST" = "vikunja-db";
                      "VIKUNJA_DATABASE_TYPE" = "mysql";
                      "VIKUNJA_DATABASE_USER" = "vikunja";
                      "VIKUNJA_DATABASE_DATABASE" = "vikunja";
                    };
                    volumes = [ 
                        "/Storage/Services/Vikunja/files:/app/vikunja/files"
                    ];
                    expose = [
                        "3456" 
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
                    ];
                };
                vukunja-db.service {
                    image = "mariadb:10";
                    command = "--character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci";
                    restart = "always";
                    env_file = [
                      "/Storage/Services/Vikunja/.env"
                    ];
                    environment = {
                        "MYSQL_USER" = "vikunja";
                        "MYSQL_DATABASE" = "vikunja";
                    };
                    volumes = [ 
                        "/Storage/Services/Vikunja/db:/var/lib/mysql"
                    ];
                    healthcheck = {
                        test = [
                            "CMD-SHELL"
                            "mysqladmin ping -h localhost -u $$MYSQL_USER --password=$$MYSQL_PASSWORD"
                        ];
                        interval = "2s";
                        start_period = "30s";
                    };
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