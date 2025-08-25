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
            services = {
                fix_wireguard_key_perms = {
                    description = "Set permissions for wireguard private key";
                    wantedBy = [ "initrd.target" ];
                    after = [ "initrd-nixos-copy-secrets.service" ];
                    before = [ "systemd-networkd.service" ];
                    unitConfig.DefaultDependencies = "no";
                    serviceConfig.Type = "oneshot";
                    script = '' chown systemd-network:systemd-network "${config.sops.secrets.wireguard_private_key.path}" '';
                };
                "initrd-reboot" = {
                    description = "Reboot system after 30 minutes in initrd";
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
                description = "Check network connectivity via pinging Heimdall";
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = pkgs.writeShellScript "networkd-check" ''
                        if ${pkgs.iputils}/bin/ping 10.100.100.1 -c5 >/dev/null; then
                            exit 0
                        else
                            exit 1
                        fi
                    '';
                };
                # If it fails enough times in 5 minutes → restart networkd
                # With 30-second interval, 10 consecutive failures = 5 minutes
                startLimitIntervalSec = 300;  # 5 minutes
                startLimitBurst = 10;         # 10 failures within 5 minutes
                unitConfig.OnFailure = "networkd-recover.service";
            };

            networkd-recover = {
                description = "Restart systemd-networkd if unable to reach Heimdall for 5 minutes";
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = pkgs.writeShellScript "networkd-recover" ''
                        ${pkgs.systemd}/bin/systemctl restart systemd-networkd
                    '';
                };
            };

            networkd-failsafe = {
                description = "Check network connectivity by pinging heimdall (failsafe)";
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = pkgs.writeShellScript "networkd-failsafe" ''
                        if ${pkgs.iputils}/bin/ping 10.100.100.1 -c5 >/dev/null; then
                            exit 0
                        else
                            exit 1
                        fi
                    '';
                };
                # If it fails enough times in 1 hours → reboot system
                # With 30-second interval, 120 consecutive failures = 1 hour
                startLimitIntervalSec = 3600;   # 1 hour in seconds
                startLimitBurst = 120;          # must fail 120 times in 1 hour
                unitConfig.OnFailure = "networkd-failsafe-reboot.service";
            };

            networkd-failsafe-reboot = {
                description = "Reboot system if unable to reach Heimdall for 6 hours";
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${pkgs.systemd}/bin/systemctl reboot";
                };
            };
        };
        timers = {
            networkd-check = {
                description = "Run networkd-check every 30 seconds";
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnBootSec = "30s";
                    OnUnitActiveSec = "30s";  # check every 30 seconds
                    Unit = "networkd-check.service";
                };
            };
            networkd-failsafe = {
                description = "Run networkd-failsafe-check every 30 seconds";
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnBootSec = "30s";
                    OnUnitActiveSec = "30s"; # check every 30 seconds
                    Unit = "networkd-failsafe.service";
                };
            };
        };

    };
}
