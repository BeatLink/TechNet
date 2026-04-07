# OpenBooks
#
# OpenBooks is an eBook downloader
#

{
    virtualisation.arion.projects.openbooks = {
        serviceName = "openbooks";
        settings = {
            services = {
                openbooks.service = {
                    image = "evanbuss/openbooks";
                    container_name = "openbooks";
                    restart = "always";
                    command = [
                      "--name" "beatlink" "--persist"
                    ];
                    volumes = [ 
                        "/Storage/Files/eBooks/OpenBooks:/books"
                    ];
                    expose = [
                        "80" 
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