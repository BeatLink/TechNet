{ inputs, config, ... }:
{
    sops.secrets.boinc_env.sopsFile = "${inputs.self}/secrets/2-server.yaml";
    virtualisation.arion.projects.boinc = {
        serviceName = "boinc";
        settings = {
            services = {
                boinc.service = {
                    image = "boinc/client";
                    container_name = "boinc";
                    restart = "always";
                    volumes = [
                        "/Storage/Services/BOINC:/var/lib/boinc"
                    ];
                    env_file = [
                        config.sops.secrets.boinc_env.path
                    ];
                    ports = [
                        "31416:31416"
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
