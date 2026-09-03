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

{ config, pkgs, lib, ... }:
{

    nginx-vhosts.pi-hole = {
        domain = "pi-hole.heimdall.technet";
        port = 9018;
    };

    services = {
        # Pi-Hole Web --------------------------------------------------------------------------------------------------------------------------------
        pihole-web = {
            enable = true;
            hostName = "127.0.0.1";
            ports = [ "127.0.0.1:9018" ];
        };

        # Pi-Hole ------------------------------------------------------------------------------------------------------------------------------------
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
                    url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/ultimate.txt";
                    description = "hagezi ultimate blocklist";
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
                {
                    url = "https://v.firebog.net/hosts/Prigent-Crypto.txt";
                    description = "Firebog crypto-mining/ransomware";
                }
                {
                    url = "https://phishing.army/download/phishing_army_blocklist_extended.txt";
                    description = "Phishing Army extended blocklist";
                }
                {
                    url = "https://urlhaus.abuse.ch/downloads/hostfile/";
                    description = "URLhaus malware distribution";
                }
                {
                    url = "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt";
                    description = "NoTrack malware";
                }
                {
                    url = "https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/generated/hosts";
                    description = "Stalkerware indicators";
                }
                {
                    url = "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt";
                    description = "DandelionSprout anti-malware";
                }
            ];
            settings = {
                webserver.acl = "-0.0.0.0/0,+127.0.0.1/32";

                dns = {
                    # Stop appending every DNS query to pihole.log. The file had
                    # reached 532MB, and it sits on the same HDD mirror
                    # everything else contends for -- now that FTL is
                    # prioritised those writes go to the front of the queue, so
                    # it is worth not making them at all.
                    #
                    # This is the key that emits dnsmasq's `log-queries`. A
                    # `log-queries=no` appended via misc.dnsmasq_lines does not
                    # work: pihole writes a bare `log-queries` earlier in the
                    # generated dnsmasq.conf, and the later assignment does not
                    # override it.
                    #
                    # Only the plain-text log is affected. FTL still records
                    # queries in its own database, so the dashboard, per-client
                    # stats and the query log UI keep working, and privacylevel
                    # stays 0.
                    queryLogging = false;

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

                        # Odin's LAN address, so odin.lan resolves at all.
                        # Hosts inside the DHCP range get a .lan name from
                        # their lease -- thor.lan and ragnarok.lan work that
                        # way -- but Odin is statically addressed below the
                        # range and never appears in the lease table.
                        #
                        # Needed before anything can CNAME to it: dnsmasq drops
                        # a cname whose target it does not already know, and
                        # does so silently.
                        "192.168.0.3 odin.lan"
                        "162.159.200.1 time.cloudflare.com" # Static IP to break the DNS/NTP circular dependency
                    ];
                    cnameRecords = [
                        "trilium-sysadmin.heimdall.technet,heimdall.technet"

                        # Services a host serves itself, declared as
                        # technet.vhosts in 0-common/1-system/networking/vhosts.nix
                        # and reachable from other machines through these.
                        #
                        # One line per service rather than a wildcard. dnsmasq
                        # accepts `cname=*.odin.lan,odin.lan` -- its own
                        # --test says the syntax is fine -- and then resolves
                        # nothing, verified against 2.93. The wildcard that
                        # does work, `address=/odin.lan/<ip>`, takes a literal
                        # address, and there is no DHCP reservation here to pin
                        # one, so it would break whenever a lease moved.
                        #
                        # These point at the host name rather than an address,
                        # so they follow the lease on their own.
                        #
                        # Worth remembering that adding a technet.vhosts entry
                        # does not add one of these. The name will work on the
                        # host itself, via its own /etc/hosts, and nowhere else.
                        "syncthing.odin.lan,odin.lan"
                        "syncthing.ragnarok.lan,ragnarok.lan"
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
                database.maxDBdays = 7;                                     # Every query row is scanned at startup, and 90 days of them held FTL's API for 20 s.
            };
            stateDirectory = "/Storage/Services/PiHole/state";
            logDirectory = "/Storage/Services/PiHole/logs";
        };

    };

    # Ensure the persistent storage is owned by pihole
    systemd.tmpfiles.settings."PiHole" = {
        "/Storage/Services/PiHole" = {
            d = {
                user = "pihole";
                group = "pihole";
                mode = "0750";
            };
            Z = {
                user = "pihole";
                group = "pihole";
                mode = "0750";
            };
        };
    };

    environment.persistence."/Storage/Services/PiHole".directories = [
        {
            directory = "/etc/pihole";
            user = "pihole";
            group = "pihole";
            mode = "0755";
        }
    ];

    systemd.services.pihole = {
        after = [ "unbound.service" ];
        requires = [ "unbound.service" ];
    };

    # Setup ordering -----------------------------------------------------------------------------------------------------------------------------
    # FTL serves the API before the gravity database is open, so the setup's list registration is gated on the lists endpoint returning data.
    systemd.services.pihole-ftl-setup.serviceConfig.ExecStartPre = lib.getExe (
        pkgs.writeShellApplication {
            name = "pihole-wait-for-gravity";
            runtimeInputs = [
                pkgs.coreutils
                pkgs.gnugrep
                config.services.pihole-ftl.piholePackage
            ];
            text = ''
                for _ in $(seq 120); do
                    if pihole api lists 2>/dev/null | grep -q '"lists"'; then
                        exit 0
                    fi
                    sleep 1
                done
                echo "gravity database still unavailable after 120s" >&2
                exit 1
            '';
        }
    );

    # DNS is on the critical path for every other machine on the network: when
    # the pool is busy, a stalled lookup does not just slow the server down, it
    # looks like the internet is broken everywhere. So FTL and the resolver it
    # forwards to are the one pair that should preempt the backup and sync jobs
    # deprioritised elsewhere, rather than queue behind them.
    #
    # Prioritising FTL alone would only move the bottleneck: pihole forwards to
    # unbound, so a starved unbound stalls FTL just the same. Both get the same
    # treatment.
    #
    # Nice and the high CPUWeight cover scheduling; best-effort/0 is the top of
    # the normal I/O class, so these still jump ahead of the idle-class backup
    # and the deprioritised sync without leaving the normal scheduling classes.
    #
    # Deliberately NOT IOSchedulingClass=realtime: FTL stopped answering queries
    # under it, leaving a 4800-deep backlog on the :53 socket while unbound
    # behind it still resolved fine. Realtime I/O is not a "more important"
    # best-effort -- it lets a process monopolise the device, and FTL's own
    # threads starved each other. Best-effort/0 gives the priority without that.
    systemd.services.pihole-ftl.serviceConfig = {
        Nice = -10;
        CPUWeight = 2000;
        IOWeight = 1000;
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = 0;
    };

    systemd.services.unbound.serviceConfig = {
        Nice = -10;
        CPUWeight = 2000;
        IOWeight = 1000;
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = 0;
    };

    # FTL serves NTP as well as DNS and DHCP, and advertises itself as the time
    # server in its DHCP leases -- but the module opens only 53 and 67, so every
    # client that took that lease was pointed at a port the firewall dropped.
    # Clients then sat at NTPSynchronized=no indefinitely: systemd-timesyncd only
    # falls back to its FallbackNTP list when no server is configured at all, and
    # a configured-but-silent one is never given up on.
    #
    # Ragnarok was 10 years behind because of this, which broke TLS to the binary
    # cache: certificates read as "not yet valid".
    networking.firewall.allowedUDPPorts = [ 123 ];
}
