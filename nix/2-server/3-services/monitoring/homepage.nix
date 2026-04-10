{ inputs, config, ... }:
{
    sops.secrets.homepage_env = {
        sopsFile = "${inputs.self}/secrets/2-server/homepage.yaml";
        owner = "homepage-dashboard";
        group = "homepage-dashboard";
    };
    services.homepage-dashboard = {
        enable = true;
        allowedHosts = "homepage.heimdall.technet,www.heimdall.technet,heimdall.technet";
        listenPort = 9610;
        environmentFiles = [ config.sops.secrets.homepage_env.path ];
        settings = {
            title = "TechNet";
            fullWidth = true;
            useEqualHeights = true;
            columns = 4;
            layout = [
                { "Personal" = { }; }
                { "Comms" = { }; }
                { "Home and Car" = { }; }
                { "Fun" = { }; }
                { "TechNet" = { }; }
                { "System" = { }; }
                {
                    "System Info" = {
                        style = "row";
                        columns = 5;
                    };
                }
            ];
        };
        widgets = [
            {
                greeting = {
                    text_size = "xl";
                    text = "Heimdall";
                };
            }
            {
                resources = {
                    cpu = true;
                    disk = "/";
                    memory = true;
                };
            }
            {
                datetime = {
                    text_size = "xl";
                    format = {
                        dateStyle = "long";
                        timeStyle = "short";
                    };
                };
            }
            {
                openmeteo = {
                    label = "Jamaica";
                    latitude = "{{HOMEPAGE_VAR_LATITUDE}}";
                    longitude = "{{HOMEPAGE_VAR_LONGITUDE}}";
                    timezone = "America/Jamaica";
                    units = "metric";
                    cache = 5;
                    format = {
                        maximumFractionDigits = 1;
                    };
                };
            }
        ];
        services = [
            {
                "Personal" = [
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
                    {
                        "Cronometer" = {
                            icon = "https://cronometer.com/favicon.svg";
                            href = "https://cronometer.com";
                            description = "Cronometer";
                            siteMonitor = "https://cronometer.com";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Liftosaur" = {
                            icon = "https://www.liftosaur.com/images/logo.svg";
                            href = "https://liftosaur.com";
                            description = "Liftosaur";
                            siteMonitor = "https://liftosaur.com";
                            statusStyle = "dot";
                        };
                    }
                ];
            }
            {
                "Comms" = [
                    {
                        "WhatsApp" = {
                            icon = "whatsapp.png";
                            href = "https://web.whatsapp.com/";
                            description = "WhatsApp";
                            siteMonitor = "https://web.whatsapp.com/";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Discord" = {
                            icon = "discord.png";
                            href = "https://discord.com/app";
                            description = "Discord";
                            siteMonitor = "https://discord.com/app";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Matrix" = {
                            icon = "matrix.png";
                            href = "https://app.element.io";
                            description = "Matrix";
                            siteMonitor = "https://app.element.io";
                            statusStyle = "dot";
                        };
                    }
                ];
            }
            {
                "Home and Car" = [
                    {
                        "Home Assistant" = {
                            icon = "home-assistant.png";
                            description = "Home Automation Manager";
                            href = "https://home-assistant.heimdall.technet";
                            siteMonitor = "https://home-assistant.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "ESPHome" = {
                            icon = "esphome.png";
                            description = "IoT Management Dashboard";
                            href = "https://esphome.heimdall.technet";
                            siteMonitor = "https://esphome.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Frigate" = {
                            icon = "frigate.png";
                            description = "CCTV Management Platform";
                            href = "https://frigate.heimdall.technet";
                            siteMonitor = "https://frigate.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Go2RTC" = {
                            icon = "go2rtc.png";
                            description = "IP Camera Streaming Platform";
                            href = "https://go2rtc.heimdall.technet";
                            siteMonitor = "https://go2rtc.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Traccar" = {
                            icon = "traccar.png";
                            description = "Vehicle Tracking Server";
                            href = "https://traccar.heimdall.technet";
                            siteMonitor = "https://traccar.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                ];
            }
            {
                "Fun" = [
                    {
                        "Reddit" = {
                            icon = "reddit.png";
                            href = "https://reddit.com/";
                            description = "Reddit";
                            siteMonitor = "https://reddit.com/";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "FreshRSS" = {
                            icon = "freshrss.png";
                            href = "https://freshrss.heimdall.technet";
                            description = "RSS Manager";
                            siteMonitor = "https://freshrss.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "YouTube" = {
                            icon = "youtube.png";
                            href = "https://youtube.com/";
                            description = "YouTube";
                            siteMonitor = "https://youtube.com/";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Calibre" = {
                            icon = "calibre.png";
                            href = "https://calibre.heimdall.technet";
                            description = "Web UI for Calibre";
                            siteMonitor = "https://calibre.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "OpenBooks" = {
                            icon = "https://raw.githubusercontent.com/evan-buss/openbooks/refs/heads/master/server/app/public/favicon-32x32.png";
                            href = "https://openbooks.heimdall.technet";
                            description = "eBook Download Manager";
                            siteMonitor = "https://openbooks.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "QBittorrent" = {
                            icon = "qbittorrent.png";
                            href = "https://qbittorrent.heimdall.technet";
                            description = "Torrent Manager";
                            siteMonitor = "https://qbittorrent.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                ];
            }
            {
                "TechNet" = [
                    {
                        "BlockURL" = {
                            icon = "no.png";
                            href = "https://blockurl.heimdall.technet";
                            description = "URL Content Blocker";
                            siteMonitor = "https://blockurl.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Pi-Hole" = {
                            icon = "pi-hole.png";
                            href = "https://pi-hole.heimdall.technet/admin";
                            description = "Ad Blocking and DNS Server";
                            siteMonitor = "https://pi-hole.heimdall.technet/admin";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Syncthing" = {
                            icon = "syncthing.png";
                            href = "https://syncthing.heimdall.technet";
                            description = "File Synchronization";
                            siteMonitor = "https://syncthing.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                ];
            }
            {
                "System" = [
                    {
                        "Grafana" = {
                            icon = "grafana.png";
                            href = "https://grafana.heimdall.technet";
                            description = "Metrics Dashboard";
                            siteMonitor = "https://grafana.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Prometheus" = {
                            icon = "prometheus.png";
                            href = "https://prometheus.heimdall.technet";
                            description = "Metrics and Alerting";
                            siteMonitor = "https://prometheus.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Loki" = {
                            icon = "loki.png";
                            href = "https://loki.heimdall.technet";
                            description = "Log Aggregation";
                            siteMonitor = "https://loki.heimdall.technet";
                            statusStyle = "dot";
                        };
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
}
