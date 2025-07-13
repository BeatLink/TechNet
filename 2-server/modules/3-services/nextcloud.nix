# NextCloud
#
# NextCloud is the Personal Information Manager (PIM) hub of the TechNet. 
# 
# Features
#   - Contacts
#   - Calendar
#   - Tasks
#   - Phone Tracking
#   - Files
#

{ config, ... }: 
{
    sops.secrets.nextcloud_env.sopsFile = ../../secrets.yaml;
    virtualisation.arion = {
        backend = "docker";
        projects.nextcloud = {
            serviceName = "nextcloud";
            settings = {
                services = {
                    nextcloud-db.service = {
                        image = "mariadb:latest";
                        container_name = "nextcloud-db";
                        restart = "always";
                        command = "--transaction-isolation=READ-COMMITTED --binlog-format=ROW";
                        volumes = [
                            "/Storage/Services/Nextcloud/db:/var/lib/mysql"
                        ];
                        env_file = [
                            config.sops.secrets.nextcloud_env.path
                        ];
                        environment = {
                            "MYSQL_DATABASE" = "nextcloud";
                            "MYSQL_USER" = "nextcloud";
                            "TZ" = "America/Jamaica";
                        };
                        expose = [
                            "3306"
                        ];
                        networks = [
                            "nextcloud"
                        ];
                    };
                    nextcloud-cron.service = {
                        image = "rcdailey/nextcloud-cronjob:latest";
                        container_name = "nextcloud-cron";
                        restart = "always";
                        depends_on = [
                            "nextcloud-app"
                        ];
                        volumes = [
                            "/var/run/docker.sock:/var/run/docker.sock:ro"
                            "/etc/localtime:/etc/localtime:ro"
                        ];
                        environment = {
                            "NEXTCLOUD_CONTAINER_NAME" = "nextcloud-app";
                            "NEXTCLOUD_CRON_MINUTE_INTERVAL" = "1";
                        };
                    };
                    nextcloud-app.service = {
                        image = "nextcloud:latest";
                        container_name = "nextcloud-app";
                        hostname = "nextcloud.heimdall.technet";
                        restart = "always";
                        links = [
                            "nextcloud-db"
                        ];    
                        volumes = [
                            "/Storage/Services/Nextcloud/nextcloud:/var/www/html"
                        ];
                        env_file = [
                            config.sops.secrets.nextcloud_env.path
                        ];
                        environment = {
                            "MYSQL_DATABASE" = "nextcloud";
                            "MYSQL_USER" = "nextcloud";
                            "MYSQL_HOST" = "nextcloud-db";
                            "TZ" = "America/Jamaica";
                        };
                        healthcheck = {
                            test = ["CMD-SHELL" "curl -sSf 'http://localhost/status.php' | grep '\"installed\":true' | grep '\"maintenance\":false' | grep '\"needsDbUpgrade\":false' || exit 1"];
                            interval = "30s";
                            retries = 3;
                        };
                        expose = [
                            "80"
                        ];
                        networks = [
                            "nextcloud"
                            "nginx-proxy-manager_public"
                        ];
                    };
                };
                networks = {
                    nextcloud = {
                        driver = "bridge";
                    };
                    nginx-proxy-manager_public = {
                        "external" = true;
                    };
                };
            };
        };
    };
}


# Time and Date
# Weather
# Emails
# RSS Feeds
# Calendar
# Todos
# Notes
# Communications

# Phone Notifications
# Computer notifications
