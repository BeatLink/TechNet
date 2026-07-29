# Networking
#
# This file configures wireguard and networking settings
#

{
    config,
    inputs,
    pkgs,
    ...
}:
let
    initrdSystemd = config.boot.initrd.systemd.package;
in
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
        sopsFile = "${inputs.self}/secrets/1-backup-server/wireguard.yaml";
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
            # ping is used by initrd-wireguard-recover to tell a genuinely working
            # tunnel from one that is merely "routable" with no peer endpoint.
            storePaths = [ "${pkgs.iputils}/bin/ping" ];

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

                "initrd-wireguard-recover" = {
                    description = "Bounce the wireguard tunnel if it is not carrying traffic";
                    unitConfig.DefaultDependencies = "no";
                    serviceConfig.Type = "oneshot";
                    script = ''
                        # wg0 reports "routable" as soon as it has an address, even with
                        # no peer endpoint and no connectivity at all -- so link state is
                        # useless here. Test whether the tunnel actually carries traffic.
                        carrying() {
                            ${pkgs.iputils}/bin/ping -c1 -W3 -I wg0 10.100.100.1 > /dev/null 2>&1
                        }

                        if carrying; then
                            echo "wireguard-recover: tunnel is carrying traffic, nothing to do"
                            exit 0
                        fi

                        # The usual failure is wg0 coming up before DNS, so the peer
                        # endpoint never resolves and is silently dropped. networkctl
                        # reconfigure does NOT re-resolve it; only a networkd restart does.
                        echo "wireguard-recover: no traffic over wg0, restarting systemd-networkd"
                        ${initrdSystemd}/bin/systemctl restart systemd-networkd || true
                        sleep 10

                        if carrying; then
                            echo "wireguard-recover: recovered after networkd restart"
                            exit 0
                        fi

                        echo "wireguard-recover: still no traffic, reconfiguring wg0 as a last resort"
                        ${initrdSystemd}/bin/networkctl reconfigure wg0 || true
                        sleep 10
                        if carrying; then
                            echo "wireguard-recover: recovered after reconfigure"
                        else
                            echo "wireguard-recover: tunnel still down, will retry on next timer tick" >&2
                        fi
                        exit 0
                    '';
                };

                "initrd-wireguard-recover-cancel" = {
                    description = "Stop the wireguard recovery loop once unlocked";
                    wantedBy = [ "initrd.target" ];
                    before = [ "initrd-cleanup.service" ];
                    unitConfig.DefaultDependencies = "no";
                    serviceConfig = {
                        Type = "oneshot";
                        RemainAfterExit = true;
                        ExecStart = "${initrdSystemd}/bin/systemctl stop initrd-wireguard-recover.timer";
                    };
                };
            };

            timers."initrd-wireguard-recover" = {
                description = "Timer to bounce the wireguard tunnel while stuck in initrd";
                timerConfig = {
                    OnBootSec = "45s";
                    OnUnitActiveSec = "60s";
                    Unit = "initrd-wireguard-recover.service";
                };
                unitConfig.DefaultDependencies = "no";
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
    };
}
