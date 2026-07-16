# Pi-Hole
#
# Pi-Hole acts as an ad-blocking system for the TechNet. More importantly, it also acts as the DNS server for all services and hosts
# in the TechNet, allowing them to be accessed via the .technet domain
#
# Links:
#     - https://github.com/pi-hole/pi-hole/
#     - https://docs.pi-hole.net/
#
# Device List
#     - Heimdall - heimdall.technet
#     - Odin - odin.technet
#     - Hela - hela.technet
#     - Thor - thor.technet
#     - ThorX - thorx.technet
#     - Ragnarok - ragnarok.technet
#

{
    config,
    inputs,
    ...
}:
{

    # Credentials ------------------------------------------------------------------------------------------------------------------------------
    sops.secrets.pihole_env.sopsFile = "${inputs.self}/secrets/2-server/pi-hole.yaml";

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
            openFirewallDNS = true;
            openFirewallDHCP = true;
            lists = [
                {
                    url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
                    description = "default blocklist";
                }
                {
                    url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt";
                    description = "hagezi blocklist";
                }
                {
                    url = "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt";
                    description = "KADhosts";
                }
                {
                    url = "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts";
                    description = "FadeMind spam";
                }
                {
                    url = "https://v.firebog.net/hosts/static/w3kbl.txt";
                    description = "Firebog suspicious";
                }
            ];
            settings = {
                dns = {
                    upstreams = [
                        "127.0.0.1#5335"
                        "1.1.1.1" # Fallback to resolve NTP if Unbound fails due to inaccurate system time
                    ];
                    hosts = [
                        "10.100.100.1  heimdall.technet"
                        "10.100.100.2  odin.technet"
                        "10.100.100.3  hela.technet"
                        "10.100.100.4  thor.technet"
                        "10.100.100.5  thorx.technet"
                        "10.100.100.6  ragnarok.technet"
                        "10.100.100.18 socket-ragnarok.technet"
                        "192.168.0.2 bltechnet.mooo.com"
                        "162.159.200.1 time.cloudflare.com" # Static IP to break the DNS/NTP circular dependency
                    ];
                    cnameRecords = [
                        "trilium-sysadmin.heimdall.technet,heimdall.technet"
                    ];
                    domain = {
                        name = "lan";
                        local = "true";
                    };
                    rateLimit = {
                        count = 10000;
                        interval = 60;
                    };
                };
                dhcp = {
                    active = true;
                    start = "192.168.0.10";
                    end = "192.168.0.254";
                    router = "192.168.0.1";
                    netmask = "255.255.255.0";
                    leaseTime = "1d";
                    rapidCommit = false;
                    logging = true;
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
        # Ensure the persistent storage is owned by pihole
        "d /Storage/Services/PiHole 0750 pihole pihole - -"
        "Z /Storage/Services/PiHole 0750 pihole pihole - -"
        "f /etc/pihole/versions 0644 pihole pihole - -"
    ];

    environment.persistence."/Storage/Services/PiHole".directories = [
        {
            directory = "/etc/pihole";
            user = "pihole";
            group = "pihole";
            mode = "0755";
        }
    ];

    systemd.services.prometheus-pihole-exporter = {
        serviceConfig = {
            EnvironmentFile = config.sops.secrets.pihole_env.path;
        };
    };

    systemd.services.pihole = {
        after = [ "unbound.service" ];
        requires = [ "unbound.service" ];
    };
}
