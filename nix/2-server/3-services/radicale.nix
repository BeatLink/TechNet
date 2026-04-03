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
    services.radicale = {
        enable = true;
        settings = {
            server = {
                hosts = [
                    "127.0.0.1:5232"
                ];
            };
            auth = {
                type = "htpasswd";
                htpasswd_filename = "/Storage/Services/Radicale/data/users";
                htpasswd_encryption = "bcrypt";
            };
            storage = {
                filesystem_folder = "/Storage/Services/Radicale/data/collections";
            };
        };
    };
    /*
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
                          environment = {
                              "TZ" = "America/Jamaica";
                              "RADICALE_CONFIG" = "/var/lib/radicale/radicale.cfg";
                          };
                          ports = [
                              "5232:5232"
                          ];
                          networks = [
                              "nginx-proxy-manager_public"
                          ];
                          healthcheck = {
                              test = [
                                  "CMD-SHELL"
                                  "wget --spider --quiet --tries=1 http://127.0.0.1:5232/.well-known/carddav || exit 1"
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
    */
    nginx-vhosts.radicale = {
        domain = "radicale.heimdall.technet";
        port = 5232;
    };
}
