# Pi-Hole
#
# Pi-Hole acts as an ad-blocking system for the TechNet. More importantly, it also acts as the DNS server for all docker services and hosts
# in the TechNet, allowing them to be accessed via the .technet domain
#
# More info at https://github.com/pi-hole/docker-pi-hole/ and https://docs.pi-hole.net/
#
# Links:
#     - https://github.com/pi-hole/pi-hole/
#
# Device List
#     - Heimdall - heimdall.technet
#     - Odin - odin.technet
#     - Hela - hela.technet
#     - Thor - thor.technet
#     - ThorX - thorx.technet
#     - Ragnarok - ragnarok.technet
#

{ config, inputs, ... }:
{
    # Credentials ------------------------------------------------------------------------------------------------------------------------------
    sops.secrets.pihole_env.sopsFile = "${inputs.self}/secrets/2-server.yaml";

    nginx-vhosts.pi-hole = {
        domain = "pi-hole.heimdall.technet";
        port = 9018;
    };

    services = {

        # Pi-Hole Web ---------------------------------------------------------------------------------------------------------------------------
        pihole-web = {
            enable = true;
            hostName = "127.0.0.1";
            ports = [ "9018" ];
        };

        # Pi-Hole --------------------------------------------------------------------------------------------------------------------------------
        pihole-ftl = {
            enable = true;
            lists = [
                {
                    url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
                    type = "block";
                    enabled = true;
                    description = "default blocklist";
                }
                {
                    url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt";
                    type = "block";
                    enabled = true;
                    description = "hagezi blocklist";
                }
            ];
            settings = {
                dns = {
                    upstreams = [
                        "8.8.8.8"
                        "8.8.4.4"
                        "1.1.1.1"
                        "1.0.0.1"

                    ];
                    hosts = [
                        "10.100.100.1  heimdall.technet"
                        "10.100.100.2  odin.technet"
                        "10.100.100.3  hela.technet"
                        "10.100.100.4  thor.technet"
                        "10.100.100.5  thorx.technet"
                        "10.100.100.6  ragnarok.technet"
                        "10.100.100.10 light-bedroom.technet"
                        "10.100.100.11 light-kitchen.technet"
                        "10.100.100.12 light-bathroom.technet"
                        "10.100.100.13 light-bedroom-desk.technet"
                        "10.100.100.14 light-outside.technet"
                        "10.100.100.16 ir-fan.technet"
                        "10.100.100.17 socket-fan.technet"
                        "10.100.100.18 socket-ragnarok.technet"
                        "10.100.100.19 sensor-bathroom.technet"
                        "10.100.100.20 sensor-bedroom.technet"
                    ];
                    cnameRecords = [
                        "ragnarok,ragnarok.technet"
                        "heimdall,heimdall.technet"
                        "odin,odin.technet"
                        "thor,thor.technet"
                        "hela,hela.technet"
                        "calibre-web.heimdall.technet,heimdall.technet"
                        "motioneye.heimdall.technet,heimdall.technet"
                        "openbooks.heimdall.technet,heimdall.technet"
                        "syncthing.heimdall.technet,heimdall.technet"
                        "trilium-sysadmin.heimdall.technet,heimdall.technet"
                    ];
                    domain = {
                        name = "technet";
                        local = "true";
                    };
                };
            };
            stateDirectory = "/Storage/Services/PiHole/state";
            logDirectory = "/Storage/Services/PiHole/logs";
        };

        # Pi-Hole Prometheus -----------------------------------------------------------------------------------------------------------------------
        prometheus.exporters.pihole = {
            enable = true;
            listenAddress = "127.0.0.1";
            port = 9019;
            piholeHostname = "127.0.0.1";
            piholePort = 9018;
            protocol = "http";
        };
    };

    systemd.tmpfiles.rules = [
        # Type Path Mode User Group Age Argument
        "f /etc/pihole/versions 0644 pihole pihole - -"
    ];

    systemd.services.prometheus-pihole-exporter = {
        serviceConfig = {
            EnvironmentFile = config.sops.secrets.pihole_env.path;
        };
    };

    virtualisation.arion.projects.pihole = {
        serviceName = "pihole2";
        settings = {
            services = {
                pihole.service = {
                    image = "pihole/pihole:latest";
                    container_name = "pihole";
                    restart = "always";
                    volumes = [
                        "/Storage/Services/PiHole/etc-pihole:/etc/pihole"
                        "/Storage/Services/PiHole/etc-dnsmasq.d:/etc/dnsmasq.d"
                    ];
                    env_file = [
                        config.sops.secrets.pihole_env.path
                    ];
                    capabilities = {
                        SYS_NICE = true;
                        SYS_TIME = true;
                    };
                    environment = {
                        "TZ" = "America/Jamaica";
                        "WEB_PORT" = "80";
                    };
                    expose = [
                        "80"
                    ];
                    ports = [
                        "127.0.0.1:9998:53/tcp"
                        "127.0.0.1:9986:53/udp"
                        "192.168.0.2:9986:53/tcp"
                        "192.168.0.2:9986:53/udp"
                        "10.100.100.1:9986:53/tcp"
                        "10.100.100.1:9986:53/udp"
                        "89:443/tcp"
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
