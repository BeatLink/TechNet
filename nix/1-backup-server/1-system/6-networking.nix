# Networking
#
# This file configures wireguard and networking settings
#

{
    config,
    pkgs,
    inputs,
    ...
}:
{
    networking = {
        # Sets the hostName
        hostName = "Ragnarok";

        # Sets the Host ID for ZFS
        hostId = "bed2ee51";

        # Use Systemd-Networkd
        useNetworkd = true;

        # Sets up DNS. The server's Pi-Hole is the main DNS with Google and Cloudfare as backup
        nameservers = [
            "10.100.100.1"
            "8.8.8.8"
            "1.1.1.1"
        ];

        # Sets the Wireguard interface as trusted in the firewall
        firewall.trustedInterfaces = [ "wg0" ];
    };

    # Loads the Wireguard private key from SOPS and sets the permissions to systemd-networkd
    sops.secrets.wireguard_private_key = {
        sopsFile = "${inputs.self}/secrets/1-backup-server.yaml";
        owner = "systemd-network";
        group = "systemd-network";
    };

    boot.initrd = {
        # Needed for wireguard in initrd for remote LUKS unlocking
        availableKernelModules = [ "wireguard" ];

        # Sops doesn't work in initrd so we use boot.initrd.secrets
        secrets."${config.sops.secrets.wireguard_private_key.path}" =
            config.sops.secrets.wireguard_private_key.path;

        systemd = {
            # The Wireguard privatekey must be owned by systemd-network to be used.
            services = {
                fix_wireguard_key_perms = {
                    description = "Set permissions for wireguard private key";
                    wantedBy = [ "initrd.target" ];
                    after = [ "initrd-nixos-copy-secrets.service" ];
                    before = [ "systemd-networkd.service" ];
                    unitConfig.DefaultDependencies = "no";
                    serviceConfig.Type = "oneshot";
                    script = ''chown systemd-network:systemd-network "${config.sops.secrets.wireguard_private_key.path}" '';
                };
                "initrd-reboot" = {
                    description = "Reboot system after 10 minutes in initrd";
                    serviceConfig = {
                        Type = "oneshot";
                        ExecStart = "systemctl reboot";
                    };
                };
            };
            # A failsafe to reboot the system if it is stuck in initrd after 10 minutes, hopefully it can fix any wireguard issues
            timers."initrd-reboot" = {
                description = "Timer to reboot system after 10 minutes in initrd";
                timerConfig = {
                    OnBootSec = "10min";
                    Unit = "initrd-reboot.service";
                };
                wantedBy = [ "timers.target" ];
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
                        AllowedIPs = [ "10.100.100.0/24" ];
                        Endpoint = "bltechnet.mooo.com:51820";
                        PersistentKeepalive = 25;
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
                    address = [ "10.100.100.6/24" ];
                    dns = [ "10.100.100.1" ];
                };
            };
        };
        services = {
            networkd-monitor = {
                description = "Monitor network connectivity and take recovery actions";
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = pkgs.writeShellScript "networkd-monitor" ''
                        STATE_FILE="/run/networkd-monitor.failures"
                        MAX_RESTARTS=10   # ~5 minutes at 30s interval
                        MAX_REBOOTS=20    # ~10 minutes at 30s interval

                        mkdir -p /run
                        failures=0
                        if [ -f "$STATE_FILE" ]; then
                          failures=$(cat "$STATE_FILE")
                        fi

                        if ${pkgs.iputils}/bin/ping -c5 -W2 10.100.100.1 >/dev/null; then
                          echo 0 > "$STATE_FILE"
                          echo "networkd-monitor: Heimdall reachable, reset counter."
                          exit 0
                        else
                          failures=$((failures + 1))
                          echo $failures > "$STATE_FILE"
                          echo "networkd-monitor: Heimdall unreachable (failure $failures)."
                          sudo networkctl reconfigure wg0
                        fi

                        if [ "$failures" -eq "$MAX_RESTARTS" ]; then
                          echo "networkd-monitor: Restarting systemd-networkd..."
                          ${pkgs.systemd}/bin/systemctl restart systemd-networkd
                        fi

                        if [ "$failures" -ge "$MAX_REBOOTS" ]; then
                          echo "networkd-monitor: Rebooting system..."
                          ${pkgs.systemd}/bin/systemctl reboot
                        fi
                    '';
                };
            };
        };
        timers = {
            networkd-monitor = {
                description = "Run networkd-monitor every 30 seconds";
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnBootSec = "30s";
                    OnUnitActiveSec = "30s";
                    Unit = "networkd-monitor.service";
                    Persistent = true;
                };
            };
        };

    };
}
