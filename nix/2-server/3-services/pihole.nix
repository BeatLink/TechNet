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

    services = {
        pihole-web = {
            enable = true;
            hostName = "heimdall.technet";
            ports = [ "82s" ];
        };
        pihole-ftl = {
            enable = true;
            lists = [
                {
                    url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
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
                };
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
                    "blockurl.heimdall.technet,heimdall.technet"
                    "calibre-web.heimdall.technet,heimdall.technet"
                    "glances.heimdall.technet,heimdall.technet"
                    "homeassistant.heimdall.technet,heimdall.technet"
                    "openbooks.heimdall.technet,heimdall.technet"
                    "pihole.heimdall.technet,heimdall.technet"
                    "syncthing.heimdall.technet,heimdall.technet"
                    "traccar.heimdall.technet,heimdall.technet"
                    "www.heimdall.technet,heimdall.technet"
                    "motioneye.heimdall.technet,heimdall.technet"
                    "heimdall,heimdall.technet"
                    "odin,odin.technet"
                    "thor,thor.technet"
                    "hela,hela.technet"
                    "esphome.heimdall.technet,heimdall.technet"
                    "trilium.heimdall.technet,heimdall.technet"
                    "uptime-kuma.heimdall.technet,heimdall.technet"
                    "ragnarok,ragnarok.technet"
                    "trilium-sysadmin.heimdall.technet,heimdall.technet"
                    "radicale.heimdall.technet,heimdall.technet"
                    "freshrss.heimdall.technet,heimdall.technet"
                    "qbittorrent.heimdall.technet,heimdall.technet"
                    "drydock.heimdall.technet,heimdall.technet"
                ];
            };
            stateDirectory = "/Storage/Services/PiHole/state";
        };
    };

    sops.secrets.pihole_env.sopsFile = "${inputs.self}/secrets/2-server.yaml";
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
                        "127.0.0.1:9986:53/tcp"
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
