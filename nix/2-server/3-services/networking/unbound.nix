{ ... }:
{
    services.unbound = {
        enable = true;
        stateDir = "/Storage/Services/Unbound";
        settings = {
            server = {
                # Network
                interface = [
                    "10.100.100.1"
                    "127.0.0.1"
                ];
                port = 5335;
                do-ip4 = true;
                do-ip6 = false;
                do-udp = true;
                do-tcp = true;

                # Privacy
                hide-identity = true;
                hide-version = true;
                qname-minimisation = true;

                # Performance
                prefetch = true;
                prefetch-key = true;
                num-threads = 2;
                so-rcvbuf = "1m";

                # DNSSEC
                auto-trust-anchor-file = "/Storage/Services/Unbound/root.key";

                # Root hints
                root-hints = "/Storage/Services/Unbound/root.hints";

                # Hardening
                harden-glue = true;
                harden-dnssec-stripped = true;
                harden-large-queries = true;
                harden-referral-path = true;
                use-caps-for-id = true;

                # Access control
                access-control = [
                    "127.0.0.1/32 allow"
                    "0.0.0.0/0 refuse"
                ];
                
                # Cache
                cache-min-ttl = 3600;
                cache-max-ttl = 86400;
                msg-cache-size = "50m";
                rrset-cache-size = "100m";
            };
        };
    };

    # Fetch root hints periodically
    systemd.services.unbound-root-hints = {
        description = "Update Unbound root hints";
        serviceConfig = {
            Type = "oneshot";
            ExecStart = "/bin/sh -c 'curl -o /Storage/Services/Unbound/root.hints https://www.internic.net/domain/named.root'";
        };
    };

    systemd.timers.unbound-root-hints = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "monthly";
            Persistent = true;
        };
    };

    environment.persistence."/Storage/Services/Unbound" = {
        directories = [
            {
                directory = "/Storage/Services/Unbound";
                user = "unbound";
                group = "unbound";
                mode = "0750";
            }
        ];
    };
}
