# https://hub.docker.com/repository/docker/beatlink/blockurl
# https://github.com/BeatLink/BlockURL

{
    virtualisation.arion.projects.blockurl = {
        serviceName = "blockurl";
        settings = {
            services = {
                blockurl.service = {
                    image = "beatlink/blockurl:latest";
                    container_name = "blockurl";
                    restart = "always";
                    volumes = [
                        "/Storage/Services/BlockURL/database:/app/database"
                    ];
                    ports = [
                        "9001:80"
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
    nginx-vhosts.blockurl = {
        domain = "blockurl.heimdall.technet";
        port = 9001;
    };
}
