{ inputs, ... }:
{
    sops.secrets.homepage_env = {
        sopsFile = "${inputs.self}/secrets/2-server/homepage.yaml";
    };
    services.homepage-dashboard = {
        enable = true;
        allowedHosts = "homepage.heimdall.technet,www.heimdall.technet,heimdall.technet";
        listenPort = 9610;
        widgets = [
            {
                resources = {
                    cpu = true;
                    disk = "/";
                    memory = true;
                };
            }
            {
                search = {
                    provider = "duckduckgo";
                    target = "_blank";
                };
            }
        ];
        services = [
            {
                "Personal Information Management" = [
                    {
                        "Trilium" = {
                            icon = "trilium.png";
                            description = "Personal Knowledgebase";
                            href = "https://trilium.heimdall.technet";
                            siteMonitor = "https://trilium.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Radicale" = {
                            icon = "radicale.png";
                            description = "Personal Information Manager for Contacts, Calendars, Tasks and more";
                            href = "https://radicale.heimdall.technet";
                            siteMonitor = "https://radicale.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                ];
            }
            {
                "Home" = [
                    {
                        "Home Assistant" = {
                            icon = "home-assistant.png";
                            description = "Home Automation Manager";
                            href = "https://home-assistant.heimdall.technet";
                            widget = {
                                type = "homeassistant";
                                url = "https://home-assistant.heimdall.technet";
                                key = "$HOMEASSISTANT_KEY";
                            };
                        };
                    }
                ];
            }
            {
                "My Second Group" = [
                    {
                        "My Second Service" = {
                            description = "Homepage is the best";
                            href = "http://localhost/";
                        };
                    }
                ];
            }
        ];
        bookmarks = [
            {
                Fitness = [
                    {
                        Cronometer = [
                            {
                                icon = "https://cronometer.com/favicon.svg";
                                href = "https://cronometer.com";
                            }
                        ];
                    }
                    {
                        Liftosaur = [
                            {
                                icon = "https://www.liftosaur.com/images/logo.svg";
                                href = "https://liftosaur.com";
                            }
                        ];
                    }
                ];
            }
            {
                Tech = [
                    {
                        GitHub = [
                            {
                                icon = "github.png";
                                href = "https://github.com/";
                            }
                        ];
                    }
                ];
            }
            {
                Social = [
                    {
                        WhatsApp = [
                            {
                                icon = "whatsapp.png";
                                href = "https://web.whatsapp.com/";
                            }
                        ];

                    }
                ];
            }
            {
                Fun = [
                    {
                        Reddit = [
                            {
                                icon = "reddit.png";
                                href = "https://reddit.com/";
                            }
                        ];

                    }
                    {
                        YouTube = [
                            {
                                icon = "youtube.png";
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
        port = 9610;
    };
    services.nginx.virtualHosts.homepage.serverAliases = [
        "heimdall.technet"
        "www.heimdall.technet"
        "heimdall"
    ];
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
                    ports = [
                        "9011:3000"
                    ];
                    networks = [
                        "nginx-proxy-manager_public"
                    ];
                    extra_hosts = [
                        "host.docker.internal:host-gateway"
                    ];
                    environment = {
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
