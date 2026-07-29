# Networking
#
# This file configures wireguard and networking settings
#

{
    config,
    inputs,
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

                # A wireguard handshake that never completed is the usual reason clevis
                # cannot reach the tang server, so the tunnel is bounced rather than the
                # machine rebooted. Escalates to restarting systemd-networkd only if
                # reconfiguring the interface alone does not bring it back.
                "initrd-wireguard-recover" = {
                    description = "Bounce the wireguard tunnel if it is not carrying traffic";
                    unitConfig.DefaultDependencies = "no";
                    serviceConfig.Type = "oneshot";
                    # grep is not in the initrd's /bin, so operational state is matched
                    # with bash's own pattern test rather than piping to it.
                    script = ''
                        routable() {
                            local state
                            state="$(${initrdSystemd}/bin/networkctl --no-legend --no-pager list wg0 2>/dev/null)"
                            [[ "$state" == *routable* ]]
                        }
                        if routable; then
                            echo "wireguard-recover: tunnel is routable, nothing to do"
                            exit 0
                        fi
                        echo "wireguard-recover: reconfiguring wg0"
                        ${initrdSystemd}/bin/networkctl reconfigure wg0 || true
                        sleep 10
                        if routable; then
                            echo "wireguard-recover: recovered after reconfigure"
                            exit 0
                        fi
                        echo "wireguard-recover: restarting systemd-networkd"
                        ${initrdSystemd}/bin/systemctl restart systemd-networkd || true
                    '';
                };

                # Reaching initrd.target means the pools unlocked and sysroot is mounted,
                # so the recovery loop stands down instead of bouncing a healthy tunnel.
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

            # Tries to bounce the tunnel every 2 minutes, starting after wait-online's
            # 120s timeout has had its chance. Keeps retrying for as long as the boot is
            # waiting -- the system is never rebooted out from under a pending unlock, so
            # an SSH session can always take over by hand instead.
            timers."initrd-wireguard-recover" = {
                description = "Timer to bounce the wireguard tunnel while stuck in initrd";
                timerConfig = {
                    OnBootSec = "3min";
                    OnUnitActiveSec = "2min";
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
