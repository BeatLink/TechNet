# Initrd Wireguard
#
# Remote unlock depends on wireguard coming up inside initrd, and on it still
# working by the time someone tries to SSH in. This module carries the parts of
# that which are the same on every host: loading the private key from sops into
# initrd, handing it to systemd-network with the right ownership, mirroring the
# booted system's networkd config into initrd, and the recovery loop that
# bounces the tunnel when it comes up dead.
#
# The recovery loop exists because a link reports "routable" as soon as it has
# an address, even when it carries no traffic at all -- so link state is not a
# usable health check and the tunnel has to be probed by pinging through it.
# The usual failure is the interface coming up before DNS, so a peer endpoint
# never resolves and is silently dropped; `networkctl reconfigure` does NOT
# re-resolve it, only a full networkd restart does. Hence restart first,
# reconfigure only as a last resort.
#
# What each host supplies is the probe (what to ping, and whether to force it
# out of a specific interface) and which links to reconfigure. Heimdall is the
# wireguard server so peers dial in to it: what has to work there is the LAN, so
# it probes the gateway rather than a peer, since a peer may legitimately be
# down or still locked itself. Ragnarok is a client, so it probes the server
# through the tunnel.
#

{
    config,
    lib,
    pkgs,
    ...
}:
let
    cfg = config.technet.initrdWireguard;

    initrdSystemd = config.boot.initrd.systemd.package;

    keyPath = config.sops.secrets.wireguard_private_key.path;

    pingArgs = lib.concatStringsSep " " (
        [ "-c1" "-W3" ]
        ++ lib.optionals (cfg.probe.interface != null) [ "-I" cfg.probe.interface ]
        ++ [ cfg.probe.address ]
    );

    reconfigure = lib.concatMapStringsSep "\n" (
        link: "${initrdSystemd}/bin/networkctl reconfigure ${link} || true"
    ) cfg.reconfigureLinks;
in
{
    options.technet.initrdWireguard = {
        enable = lib.mkEnableOption "wireguard in initrd for remote unlock, with a recovery loop";

        sopsFile = lib.mkOption {
            type = lib.types.path;
            description = ''
                sops file holding wireguard_private_key for this host. The key is
                copied into the initrd via boot.initrd.secrets, because sops itself
                does not run there.
            '';
        };

        probe = {
            address = lib.mkOption {
                type = lib.types.str;
                description = ''
                    Address the recovery loop pings to decide whether the network is
                    actually carrying traffic.
                '';
            };

            interface = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                    Interface to force the probe out of (ping -I). Set this when the
                    probe must go through the tunnel specifically; leave null to let
                    routing choose, which is what you want when probing the LAN.
                '';
            };
        };

        reconfigureLinks = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = ''
                Links to `networkctl reconfigure` as a last resort, after restarting
                networkd has failed to bring traffic back.
            '';
        };

        kernelModules = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = ''
                Extra initrd kernel modules beyond wireguard itself -- in practice the
                host's ethernet NIC driver, which must be present for the tunnel to
                have anything to run over.
            '';
        };
    };

    config = lib.mkIf cfg.enable {
        networking.useNetworkd = true;

        sops.secrets.wireguard_private_key = {
            sopsFile = cfg.sopsFile;
            owner = "systemd-network";
            group = "systemd-network";
        };

        systemd.network.enable = true;

        boot.initrd = {
            availableKernelModules = [ "wireguard" ] ++ cfg.kernelModules;

            # Sops doesn't work in initrd so we use boot.initrd.secrets
            secrets."${keyPath}" = keyPath;

            systemd = {
                # ping is used by initrd-wireguard-recover to tell a genuinely working
                # link from one that is merely "routable" but carrying no traffic.
                storePaths = [ "${pkgs.iputils}/bin/ping" ];

                services = {
                    # The Wireguard privatekey must be owned by systemd-network to be used.
                    fix_wireguard_key_perms = {
                        description = "Set permissions for wireguard private key";
                        wantedBy = [ "initrd.target" ];
                        after = [ "initrd-nixos-copy-secrets.service" ];
                        before = [ "systemd-networkd.service" ];
                        unitConfig.DefaultDependencies = "no";
                        serviceConfig.Type = "oneshot";
                        script = ''chown systemd-network:systemd-network "${keyPath}"'';
                    };

                    "initrd-wireguard-recover" = {
                        description = "Bounce the wireguard tunnel if it is not carrying traffic";
                        unitConfig.DefaultDependencies = "no";
                        serviceConfig.Type = "oneshot";
                        script = ''
                            carrying() {
                                ${pkgs.iputils}/bin/ping ${pingArgs} > /dev/null 2>&1
                            }

                            if carrying; then
                                echo "wireguard-recover: carrying traffic, nothing to do"
                                exit 0
                            fi

                            echo "wireguard-recover: no traffic, restarting systemd-networkd"
                            ${initrdSystemd}/bin/systemctl restart systemd-networkd || true
                            sleep 10

                            if carrying; then
                                echo "wireguard-recover: recovered after networkd restart"
                                exit 0
                            fi

                            echo "wireguard-recover: still no traffic, reconfiguring links as a last resort"
                            ${reconfigure}
                            sleep 10
                            if carrying; then
                                echo "wireguard-recover: recovered after reconfigure"
                            else
                                echo "wireguard-recover: still down, will retry on next timer tick" >&2
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
    };
}
