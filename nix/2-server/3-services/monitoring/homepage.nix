{ config, ... }:
{
    sops.secrets.homepage_env = {
        sopsFile = "${config.technet.secrets.path}/homepage.yaml";
    };

    # Widget credentials that already exist as their own secrets, rendered into Homepage's variable names instead of being copied into homepage.yaml.
    sops.templates."homepage-widgets.env".content = ''
        HOMEPAGE_VAR_TRILIUM_KEY=${config.sops.placeholder.trilium_etapi_token}
        HOMEPAGE_VAR_FRESHRSS_PASS=${config.sops.placeholder.freshrss_api_password}
        HOMEPAGE_VAR_CALIBRE_PASS=${config.sops.placeholder.calibre_web_vigil_password}
    '';

    services.homepage-dashboard = {
        enable = true;
        allowedHosts = "dashboard.heimdall.technet,www.heimdall.technet,heimdall.technet";
        listenPort = 9610;
        environmentFiles = [
            # homepage_env still carries its own stale TRILIUM key; the template after it re-sets it, and systemd lets the last assignment win.
            # Syncthing's API key is in here too: it generates its own, so the live value was captured once by hand (see syncthing.nix for where Vigil reads it).
            config.sops.secrets.homepage_env.path
            config.sops.templates."homepage-widgets.env".path
        ];
        settings = {
            title = "TechNet";
            headerStyle = "boxed";
            fullWidth = true;
            useEqualHeights = true;
            columns = 4;
            disableCollapse = "true";
            hideVersion = true;
            disableUpdateCheck = true;
            layout = [
                { "Personal" = { }; }
                { "Comms" = { }; }
                { "Home and Car" = { }; }
                { "Fun" = { }; }
                { "TechNet" = { }; }
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
                    text = "TechNet";
                };
            }
            {
                resources = {
                    label = "System";
                    cpu = true;
                    memory = true;
                    network = true;
                    cputemp = true;
                    tempmin = 0;
                    tempmax = 100;
                    units = "metric";
                    refresh = 3000;
                };
            }
            {
                resources = {
                    label = "Storage";
                    disk = [
                        "/"
                        "/boot"
                        "/Storage"
                    ];
                    diskUnits = "bytes";
                    refresh = 3000;
                };
            }
            {
                datetime = {
                    text_size = "xl";
                    format = {
                        dateStyle = "short";
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
                            widget = {
                                type = "trilium";
                                url = "http://127.0.0.1:8080";
                                key = "{{HOMEPAGE_VAR_TRILIUM_KEY}}";
                            };
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
                            widget = {
                                type = "homeassistant";
                                url = "http://127.0.0.1:8123";
                                key = "{{HOMEPAGE_VAR_HOMEASSISTANT_KEY}}";
                            };
                        };
                    }
                    {
                        "ESPHome" = {
                            icon = "esphome.png";
                            description = "IoT Management Dashboard";
                            href = "https://esphome.heimdall.technet";
                            siteMonitor = "https://esphome.heimdall.technet";
                            statusStyle = "dot";
                            widget = {
                                type = "esphome";
                                url = "http://127.0.0.1:6052";
                                username = "{{HOMEPAGE_VAR_ESPHOME_USER}}";
                                password = "{{HOMEPAGE_VAR_ESPHOME_PASS}}";
                                fields = [
                                    "total"
                                    "online"
                                    "offline_alt"
                                ];
                            };
                        };
                    }
                    {
                        "Frigate" = {
                            icon = "frigate.png";
                            description = "CCTV Management Platform";
                            href = "https://frigate.heimdall.technet";
                            siteMonitor = "https://frigate.heimdall.technet";
                            statusStyle = "dot";
                            widget = {
                                type = "frigate";
                                url = "http://127.0.0.1:9310";
                                username = "{{HOMEPAGE_VAR_FRIGATE_USER}}";
                                password = "{{HOMEPAGE_VAR_FRIGATE_PASS}}";
                            };
                        };
                    }
                    # Traccar is switched off (see home-automation/traccar.nix).
                    /*
                      {
                          "Traccar" = {
                              icon = "traccar.png";
                              description = "Vehicle Tracking Server";
                              href = "https://traccar.heimdall.technet";
                              siteMonitor = "https://traccar.heimdall.technet";
                              statusStyle = "dot";
                          };
                      }
                    */
                    {
                        "MQTT" = {
                            icon = "mosquitto.png";
                            description = "Message Broker Client";
                            href = "https://mqtt-web.heimdall.technet";
                            siteMonitor = "https://mqtt-web.heimdall.technet";
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
                            widget = {
                                type = "freshrss";
                                url = "http://freshrss.heimdall.technet"; # nginx's catch-all drops requests to the bare IP with 444, so the vhost name is required
                                username = "beatlink";
                                password = "{{HOMEPAGE_VAR_FRESHRSS_PASS}}";
                            };
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
                            href = "https://calibre-web.heimdall.technet";
                            description = "Web UI for Calibre";
                            siteMonitor = "https://calibre-web.heimdall.technet";
                            statusStyle = "dot";
                            widget = {
                                type = "calibreweb";
                                url = "http://127.0.0.1:8083";
                                username = "vigil";
                                password = "{{HOMEPAGE_VAR_CALIBRE_PASS}}";
                            };
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
                            href = "https://pi-hole.heimdall.technet";
                            description = "Ad Blocking and DNS Server";
                            siteMonitor = "https://pi-hole.heimdall.technet";
                            statusStyle = "dot";
                            widget = {
                                type = "pihole";
                                url = "http://127.0.0.1:9018"; # Pi-hole's own webserver ACL allows loopback only
                                version = 6;
                                key = "{{HOMEPAGE_VAR_PIHOLE_KEY}}";
                            };
                        };
                    }
                    {
                        "Syncthing" = {
                            icon = "syncthing.png";
                            href = "https://syncthing.heimdall.technet";
                            description = "File Synchronization";
                            siteMonitor = "https://syncthing.heimdall.technet";
                            statusStyle = "dot";
                            widget = {
                                type = "syncthing";
                                url = "http://127.0.0.1:8384";
                                key = "{{HOMEPAGE_VAR_SYNCTHING_KEY}}";
                            };
                        };
                    }
                    {
                        "Syncthing (Odin)" = {
                            icon = "syncthing.png";
                            href = "https://syncthing-odin.heimdall.technet";
                            description = "File Synchronization on Odin";
                            siteMonitor = "https://syncthing-odin.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Syncthing (Ragnarok)" = {
                            icon = "syncthing.png";
                            href = "https://syncthing-ragnarok.heimdall.technet";
                            description = "File Synchronization on Ragnarok";
                            siteMonitor = "https://syncthing-ragnarok.heimdall.technet";
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
                            widget = {
                                type = "qbittorrent";
                                url = "http://127.0.0.1:9050";
                                username = "{{HOMEPAGE_VAR_QBITTORRENT_USER}}";
                                password = "{{HOMEPAGE_VAR_QBITTORRENT_PASS}}";
                            };
                        };
                    }
                    {
                        "Jackett" = {
                            icon = "jackett.png";
                            href = "https://jackett.heimdall.technet";
                            description = "Torrent Indexer Proxy";
                            siteMonitor = "https://jackett.heimdall.technet";
                            statusStyle = "dot";
                            widget = {
                                type = "jackett";
                                url = "http://127.0.0.1:9117"; # No admin password is set, so the widget needs no credential
                            };
                        };
                    }
                    {
                        "Attic" = {
                            icon = "mdi-package-variant-closed";
                            href = "https://attic.heimdall.technet";
                            description = "Nix Binary Cache";
                            siteMonitor = "https://attic.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Atuin" = {
                            icon = "mdi-console-line";
                            href = "https://atuin.heimdall.technet/healthz"; # No web UI on this vhost, so the health endpoint is the only 200
                            description = "Shell History Sync Server";
                            siteMonitor = "https://atuin.heimdall.technet/healthz";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Atuin Web" = {
                            icon = "mdi-history";
                            href = "https://atuin-web.heimdall.technet";
                            description = "Shell History Browser";
                            siteMonitor = "https://atuin-web.heimdall.technet/healthz";
                            statusStyle = "dot";
                        };
                    }
                    {
                        "Vigil" = {
                            icon = "uptime-kuma.png";
                            href = "https://vigil.heimdall.technet";
                            description = "Network and Systems Monitor";
                            siteMonitor = "https://vigil.heimdall.technet";
                            statusStyle = "dot";
                        };
                    }
                ];
            }
        ];
    };
    systemd.services.homepage-dashboard.environment.HOSTNAME = "127.0.0.1";

    # Homepage reads these once and caches; nothing in the unit depends on them,
    # so a rebuild that only edits this file leaves the old dashboard on screen
    # until the service happens to restart. A tile added here was in
    # /etc/homepage-dashboard/services.yaml immediately and on the page only
    # after a manual restart -- which reads as the rebuild not having worked.
    systemd.services.homepage-dashboard.restartTriggers = [
        config.environment.etc."homepage-dashboard/services.yaml".source
        config.environment.etc."homepage-dashboard/settings.yaml".source
        config.environment.etc."homepage-dashboard/widgets.yaml".source
        config.environment.etc."homepage-dashboard/bookmarks.yaml".source
        config.environment.etc."homepage-dashboard/custom.css".source
        config.environment.etc."homepage-dashboard/custom.js".source
    ];

    nginx-vhosts.homepage = {
        domain = "dashboard.heimdall.technet";
        port = 9610;
    };
    services.nginx.virtualHosts.homepage.serverAliases = [
        "heimdall.technet"
        "www.heimdall.technet"
        "heimdall"
    ];
}
