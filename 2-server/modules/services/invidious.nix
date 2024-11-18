{ config, lib, pkgs, modulesPath, ... }: 
{
    sops.secrets.invidious_env.sopsFile = ../../secrets.yaml;
    sops.secrets.invidiousdb_env.sopsFile = ../../secrets.yaml;
    virtualisation.arion.projects.invidious = {
        serviceName = "invidious";
        settings = {
            services = {
                invidious.service = {
                    image = "quay.io/invidious/invidious:latest";
                    container_name = "invidious";
                    restart = "always";
                    env_file = [
                        config.sops.secrets.invidious_env.path
                    ];
                    expose = [
                        "3000" 
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
                    ];
                    healthcheck = {
                        test = ["CMD-SHELL" "wget -nv --tries=1 --spider http://127.0.0.1:3000/api/v1/trending || exit 1"];
                        interval = "30s";
                        retries = 3;
                        timeout = "5s";
                    };
                    depends_on = [
                      "invidious-db"
                    ];
                };
                inv_sig_helper.service = {
                    image = "quay.io/invidious/inv-sig-helper:latest";
                    container_name = "inv_sig_helper";
                    restart = "always";
                    init = true;
                    command = ["--tcp", "0.0.0.0:12999"];
                    environment = {
                        RUST_LOG = "info";
                    };
                    cap_drop = [
                        "ALL"
                    ];
                    read_only = true;
                    security_opt = [
                        "no-new-privileges:true"
                    ];
                    expose = [
                        "12999" 
                    ];
                };
                invidious-db.service = {
                    image = "docker.io/library/postgres:14";
                    container_name = "invidious-db";
                    restart = "always";
                    env_file = [
                        config.sops.secrets.invidiousdb_env.path
                    ];
                    volumes = [ 
                        "/Storage/Services/Invidious/database:/var/lib/postgresql/data"
                        "/Storage/Services/Invidious/invidious/config/sql:/config/sql"
                        "/Storage/Services/Invidious/invidious/docker/init-invidious-db.sh:/docker-entrypoint-initdb.d/init-invidious-db.sh"
                    ];
                    healthcheck = {
                        test = ["CMD-SHELL" "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"];
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
