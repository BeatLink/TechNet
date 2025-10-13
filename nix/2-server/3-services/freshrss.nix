# FreshRSS
#
# FreshRSS is the RSS Feed Manager
#

# { inputs, config, ... }:
{
    /*
      sops.secrets.freshrss_password.sopsFile = "${inputs.self}/secrets/2-server.yaml";

      services.freshrss = {
          enable = true;
          baseUrl = "https://freshrss.heimdall.technet";
          dataDir = "/Storage/Services/FreshRSS/data";
          defaultUser = "beatlink";
          passwordFile = config.sops.secrets.freshrss_password.path;

      };
    */

    virtualisation.arion.projects.freshrss = {
        serviceName = "freshrss";
        settings = {
            services = {
                freshrss.service = {
                    image = "freshrss/freshrss:latest";
                    container_name = "freshrss";
                    hostname = "freshrss";
                    restart = "always";
                    environment = {
                        "LISTEN" = "0.0.0.0:80";
                        "CRON_MIN" = "1,31";
                        "TZ" = "America/Jamaica";
                    };
                    volumes = [
                        "/Storage/Services/FreshRSS/data:/var/www/FreshRSS/data"
                        "/Storage/Services/FreshRSS/extensions:/var/www/FreshRSS/extensions"
                    ];
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
