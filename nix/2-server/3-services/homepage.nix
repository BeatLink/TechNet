{

    services.homepage-dashboard = {
        enable = true;
        allowedHosts = "homepage.heimdall.technet,127.0.0.1:9011";
        listenPort = 9011;
        bookmarks = [
            {
                Social = [
                    {
                        Reddit = [
                            {
                                abbr = "RE";
                                href = "https://reddit.com/";
                            }
                        ];
                    }
                ];
            }
            {
                Entertainment = [
                    {
                        YouTube = [
                            {
                                abbr = "YT";
                                href = "https://youtube.com/";
                            }
                        ];

                    }
                ];
            }
        ];
    };

    nginx-vhosts.homepage = {
        domain = "homepage.heimdall.technet";
        port = 9011;
    };
    virtualisation.arion.projects.homepage = {
        serviceName = "homepage";
        settings = {
            services = {
                homepage.service = {
                    image = "ghcr.io/gethomepage/homepage:latest";
                    container_name = "homepage";
                    restart = "always";
                    volumes = [
                        "/Storage/Services/Homepage/config:/app/config"
                        "/var/run/docker.sock:/var/run/docker.sock"
                    ];
                    expose = [
                        "3000"
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
                    ];
                    extra_hosts = [
                        "host.docker.internal:host-gateway"
                    ];
                    environment = {
                        "HOMEPAGE_ALLOWED_HOSTS" = "www.heimdall.technet,heimdall.technet";
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
