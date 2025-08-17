# Networking
#
# This file configures wireguard and networking settings
#

{ config, pkgs, ... }:
{
    networking = {
        # Sets the hostName
        hostName = "Ragnarok";

        # Sets the Host ID for ZFS
        hostId = "bed2ee51";

        # Use Systemd-Networkd
        useNetworkd = true;

        # Sets up DNS. The server's Pi-Hole is the main DNS with Google and Cloudfare as backup
        nameservers = [ "10.100.100.1" "8.8.8.8" "1.1.1.1" ];
        
        # Sets the Wireguard interface as trusted in the firewall
        firewall.trustedInterfaces = ["wg0"];
    };

    # Loads the Wireguard private key from SOPS and sets the permissions to systemd-networkd
    sops.secrets.wireguard_private_key = {
        sopsFile = ../../secrets.yaml;
        owner = "systemd-network";
        group = "systemd-network";
    };

    boot.initrd = {
        # Needed for wireguard in initrd for remote LUKS unlocking
        availableKernelModules = ["wireguard"];
        
        # Sops doesn't work in initrd so we use boot.initrd.secrets
        secrets."${config.sops.secrets.wireguard_private_key.path}" = config.sops.secrets.wireguard_private_key.path;

        systemd = {
            # The Wireguard privatekey must be owned by systemd-network to be used.
            services.fix_wireguard_key_perms = {
                description = "Set permissions for wireguard private key";
                wantedBy = [ "initrd.target" ];
                after = [ "initrd-nixos-copy-secrets.service" ];
                before = [ "systemd-networkd.service" ];
                unitConfig.DefaultDependencies = "no";
                serviceConfig.Type = "oneshot";
                script = '' chown systemd-network:systemd-network "${config.sops.secrets.wireguard_private_key.path}" '';
            };

            # Sets up systemd-networkd in initrd using the same configuration from the booted system's network stack
            network = config.systemd.network;
        };
    };

    systemd = {
        network = {
            enable = true;
            netdevs."wg0" = {
                netdevConfig = {
                    Kind = "wireguard";
                    Name = "wg0";
                };
                wireguardConfig = {
                    PrivateKeyFile = config.sops.secrets.wireguard_private_key.path;
                    ListenPort = 51820;
                };
                wireguardPeers = [
                    {
                        # Server
                        PublicKey = "SLW2DFKk+Cf5K5KZl0OLYrEGyqTCqYHBKV2mTA3W2hQ=";
                        AllowedIPs = ["10.100.100.0/24"];
                        Endpoint = "72.252.37.234:51820";
                        PersistentKeepalive = 5;
                    }
                ];
            };
            networks = {
                "end0" = {
                    matchConfig.Name = "end0";
                    networkConfig.DHCP = "ipv4";
                    linkConfig.RequiredForOnline = "routable";
                };
                "wg0" = {
                    matchConfig.Name = "wg0";
                    address = ["10.100.100.5/24"];
                    dns = [ "10.100.100.1"];
                };
            };
        };

        services = {
            networkd-check = {
                description = "Check network connectivity via Uptime Kuma push";
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = pkgs.writeShellScript "networkd-check" ''
                        #!/usr/bin/env bash
                        KUMA_URL="https://uptime-kuma.heimdall.technet/api/push/WCLW4SB6K8?status=up&msg=Network%2fCheck%2fSuccessful"

                        # attempt the push; exit 0 if successful, 1 if failed
                        if ${pkgs.curl}/bin/curl -fsS "$KUMA_URL" >/dev/null; then
                            exit 0
                        else
                            exit 1
                        fi
                    '';
                };
                # If it fails enough times in 5 minutes → restart networkd
                # With 5-second interval, 60 consecutive failures = 5 minutes
                startLimitIntervalSec = 300;  # 5 minutes
                startLimitBurst = 60;         # 60 failures within 5 minutes
                unitConfig.OnFailure = "networkd-recover.service";
            };

            networkd-recover = {
                description = "Restart systemd-networkd and report recovery with downtime";
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = pkgs.writeShellScript "networkd-recover" ''
                        #!/usr/bin/env bash
                        KUMA_URL="https://uptime-kuma.heimdall.technet/api/push/WCLW4SB6K8"

                        # each failure represents 5 seconds of downtime
                        FAIL_COUNT="''${SYSTEMD_SERVICE_RESULT:-60}"
                        INTERVAL_SEC=5
                        DOWNTIME=$((FAIL_COUNT * INTERVAL_SEC))

                        # restart networkd
                        systemctl restart systemd-networkd

                        # report recovery with downtime in seconds
                        ${pkgs.curl}/bin/curl -fsS "''${KUMA_URL}?status=up&msg=Recovered%2fafter%2f''${DOWNTIME}%2fsec" >/dev/null
                    '';
                };
            };

            networkd-failsafe = {
                description = "Reboot if Uptime Kuma push fails repeatedly for 12 hours";
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = pkgs.writeShellScript "networkd-failsafe" ''
                        #!/usr/bin/env bash
                        KUMA_URL="https://uptime-kuma.heimdall.technet/api/push/WCLW4SB6K8?status=up&msg=Network%2fFailsafe%2fCheck%2fSuccessful"

                        # exit 0 on success, 1 on failure
                        if ${pkgs.curl}/bin/curl -fsS "$KUMA_URL" >/dev/null; then
                            exit 0
                        else
                            exit 1
                        fi
                    '';
                };
                # Systemd tracks failures
                startLimitIntervalSec = 43200; # 12 hours in seconds
                startLimitBurst = 12;          # must fail 12 times in 12 hours
                unitConfig.OnFailure = "networkd-failsafe-reboot.service";
            };

            networkd-failsafe-reboot = {
                description = "Reboot system after 12 consecutive Uptime Kuma failures";
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${pkgs.systemd}/bin/systemctl reboot";
                };
            };
        };
        timers = {
            networkd-check = {
                description = "Run networkd-check every 5 seconds";
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnBootSec = "5s";
                    OnUnitActiveSec = "5s";  # check every 5 seconds
                    Unit = "networkd-check.service";
                };
            };
            networkd-failsafe = {
                description = "Run Uptime Kuma failsafe check every hour";
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnBootSec = "10min";
                    OnUnitActiveSec = "1h"; # every hour
                    Unit = "networkd-failsafe.service";
                };
            };
        };
    };
}
