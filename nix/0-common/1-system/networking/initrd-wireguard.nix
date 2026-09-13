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
# It runs on a timer from 45s into the initrd until switch-root, which stops
# every initrd unit; nothing has to cancel it by hand.
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

    peer = cfg.peer;
    peerTemplate = "${peer.netdev}-peer.conf";
    peerRelPath = "systemd/network/${peer.netdev}.netdev.d/50-peer.conf";
    peerPath = "/etc/${peerRelPath}";

    pingArgs = lib.concatStringsSep " " (
        [
            "-c1"
            "-W3"
        ]
        ++ lib.optionals (cfg.probe.interface != null) [
            "-I"
            cfg.probe.interface
        ]
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

        peer = lib.mkOption {
            type = lib.types.nullOr (
                lib.types.submodule {
                    options = {
                        netdev = lib.mkOption {
                            type = lib.types.str;
                            example = "wg0";
                            description = "Name of the systemd.network netdev this peer belongs to.";
                        };

                        publicKey = lib.mkOption {
                            type = lib.types.str;
                            description = "The peer's wireguard public key.";
                        };

                        port = lib.mkOption {
                            type = lib.types.port;
                            default = 51820;
                            description = "Port the peer listens on.";
                        };

                        allowedIPs = lib.mkOption {
                            type = lib.types.listOf lib.types.str;
                            description = "Traffic routed into the tunnel.";
                        };

                        persistentKeepalive = lib.mkOption {
                            type = lib.types.int;
                            default = 25;
                            description = "Seconds between keepalives, which a NATed client needs to stay reachable.";
                        };
                    };
                }
            );
            default = null;
            description = ''
                The peer this host dials out to, declared here instead of in
                systemd.network.netdevs because its endpoint is the home
                connection's dynamic-DNS name and that name is a secret. The
                whole [WireGuardPeer] section is rendered from sops into a
                netdev drop-in rather than into the nix store, and copied into
                the initrd the same way the private key is.

                Leave this null on the host that peers dial in to, which has no
                endpoint of its own to point at.
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

        # Netdev drop-ins are parsed after the main file, so this is the only [WireGuardPeer] section wg0 has and the endpoint stays out of the store.
        sops.templates = lib.optionalAttrs (cfg.peer != null) {
            ${peerTemplate} = {
                content = ''
                    [WireGuardPeer]
                    PublicKey=${cfg.peer.publicKey}
                    AllowedIPs=${lib.concatStringsSep "," cfg.peer.allowedIPs}
                    Endpoint=${config.sops.placeholder.ddns_hostname}:${toString cfg.peer.port}
                    PersistentKeepalive=${toString cfg.peer.persistentKeepalive}
                '';
                owner = "systemd-network";
                group = "systemd-network";
            };
        };

        environment.etc = lib.optionalAttrs (cfg.peer != null) {
            ${peerRelPath}.source = config.sops.templates.${peerTemplate}.path;
        };

        systemd.network.enable = true;

        boot.initrd = {
            availableKernelModules = [ "wireguard" ] ++ cfg.kernelModules;

            # Sops doesn't work in initrd so we use boot.initrd.secrets
            secrets = {
                "${keyPath}" = keyPath;
            }
            // lib.optionalAttrs (cfg.peer != null) {
                "${peerPath}" = config.sops.templates.${peerTemplate}.path;
            };

            systemd = {
                # ping is used by initrd-wireguard-recover to tell a genuinely working
                # link from one that is merely "routable" but carrying no traffic.
                storePaths = [ "${pkgs.iputils}/bin/ping" ];

                services = {
                    # The initrd appender copies secrets in as root, but networkd reads them as systemd-network.
                    fix_wireguard_key_perms = {
                        description = "Set permissions for the wireguard secrets copied into the initrd";
                        wantedBy = [ "initrd.target" ];
                        after = [ "initrd-nixos-copy-secrets.service" ];
                        before = [ "systemd-networkd.service" ];
                        unitConfig.DefaultDependencies = "no";
                        serviceConfig.Type = "oneshot";
                        script = ''
                            chown systemd-network:systemd-network "${keyPath}"
                        ''
                        + lib.optionalString (cfg.peer != null) ''
                            chown systemd-network:systemd-network "${peerPath}"
                        '';
                    };

                    "initrd-wireguard-recover" = {
                        description = "Bounce the wireguard tunnel if it is not carrying traffic";
                        # Stopped by the switch-root isolate like every other initrd unit; the conflict only makes sure a restart never lands mid-handover.
                        before = [ "initrd-switch-root.target" ];
                        conflicts = [ "initrd-switch-root.target" ];
                        unitConfig.DefaultDependencies = "no";
                        serviceConfig = {
                            Type = "oneshot";
                            # A run in progress is killed by the switch-root isolate, and without this the resulting failure survives into the booted system.
                            SuccessExitStatus = "0 SIGTERM";
                        };
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

                };

                timers."initrd-wireguard-recover" = {
                    description = "Timer to bounce the wireguard tunnel while stuck in initrd";
                    timerConfig = {
                        OnBootSec = "45s";
                        OnUnitActiveSec = "60s";
                        Unit = "initrd-wireguard-recover.service";
                    };
                    before = [ "initrd-switch-root.target" ];
                    conflicts = [ "initrd-switch-root.target" ];
                    unitConfig.DefaultDependencies = "no";
                    wantedBy = [ "timers.target" ];
                };

                # Sets up systemd-networkd in initrd using the same configuration from the booted system's network stack
                network = config.systemd.network;
            };
        };
    };
}
