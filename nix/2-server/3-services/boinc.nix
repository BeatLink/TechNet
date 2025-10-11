{
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
                    expose = [
                        "31416" 
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