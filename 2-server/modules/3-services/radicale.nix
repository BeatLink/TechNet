# Radicale
#
# Radicale is a lightweight contacts and calendar manager for TechNet.
#
# Features
#   - Contacts
#   - Calendar
#   - Tasks
#

{
    # sops.secrets.radicale_env.sopsFile = ../../secrets.yaml;
    virtualisation.arion = {
        backend = "docker";
        projects.radicale = {
            serviceName = "radicale";
            settings = {
                services = {
                    radicale.service = {
                        image = "ghcr.io/kozea/radicale:latest";
                        container_name = "radicale";
                        restart = "always";
                        volumes = [
                            "/Storage/Services/Radicale/data:/var/lib/radicale"
                        ];
                        /*
                          env_file = [
                              config.sops.secrets.nextcloud_env.path
                          ];
                        */
                        environment = {
                            "TZ" = "America/Jamaica";
                            "RADICALE_CONFIG" = "/Storage/Services/Radicale/radicale.cfg";
                        };
                        expose = [
                            "5232"
                        ];
                        networks = [
                            "nginx-proxy-manager_public"
                        ];
                        healthcheck = {
                            test = [
                                "CMD-SHELL"
                                "curl -f http://localhost:5232/ || exit 1"
                            ];
                            interval = "30s";
                            retries = 3;
                            timeout = "5s";
                        };
                    };
                };
                networks = {
                    nginx-proxy-manager_public = {
                        "external" = true;
                    };
                };
            };
        };
    };
}
