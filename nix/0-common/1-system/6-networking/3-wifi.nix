# WiFi and WireGuard client profiles
#
# The NetworkManager hosts (the laptop and the phone) connect to the same set of
# networks, and the parts that identify those networks are a shared contract: an
# SSID typo or the wrong PSK variable does not fail at build time, it fails as a
# device that silently will not associate. The WireGuard server's public key and
# endpoint are the same kind of fact -- they describe Heimdall, not the client.
#
# So this module owns *who we connect to* and each host owns *how it addresses
# itself* once connected. IP configuration is deliberately NOT generalized: Odin
# holds a static LAN lease and disables IPv6, Thor is DHCP with IPv6 auto, and
# Odin split-tunnels (allowed-ips = 10.100.100.0/24) while Thor routes everything
# over the tunnel (0.0.0.0/0). Those are real per-device decisions, not drift.
#
# Each network is emitted only if the host gives it an `ipv4` block, so a host
# opts in per network by addressing it.
#

{
    config,
    lib,
    ...
}:
let
    cfg = config.technet.wifi;

    # Heimdall, as seen by a client. The peer section name embeds the public key,
    # which is why this is a single string rather than a structured attrset.
    serverPeer = "wireguard-peer.SLW2DFKk+Cf5K5KZl0OLYrEGyqTCqYHBKV2mTA3W2hQ=";
    serverEndpoint = "bltechnet.mooo.com:51820";

    # SSID and PSK variable per network. The PSK values are read from the
    # environment file at activation time, so what is stored here is the variable
    # name, not a secret.
    networks = {
        "TechNet Wi-Fi" = {
            ssid = "TechNet Wi-Fi";
            psk = "$TECHNET_WIFI_PASSWORD";
        };
        "Digicel_5G_WiFi_5tDQ" = {
            ssid = "Digicel_5G_WiFi_5tDQ";
            psk = "$FAMILY_HOME_WIFI_PASSWORD";
        };
        "Thor Hotspot" = {
            ssid = "Thor";
            psk = "$THOR_WIFI_PASSWORD";
        };
    };

    wifiProfile =
        name:
        let
            net = networks.${name};
            host = cfg.networks.${name};
        in
        {
            connection = {
                id = name;
                type = "wifi";
            }
            // host.connection;
            wifi = {
                ssid = net.ssid;
            }
            // host.wifi;
            wifi-security = {
                key-mgmt = "wpa-psk";
                psk = net.psk;
            }
            // host.wifi-security;
            inherit (host) ipv4 ipv6;
        };

    wgProfile = {
        connection = {
            id = "TechNet Wireguard";
            type = "wireguard";
            interface-name = "wireguard0";
        }
        // cfg.wireguard.connection;
        wireguard = {
            private-key = "$WIREGUARD_PRIVATE_KEY";
        }
        // cfg.wireguard.wireguard;
        ${serverPeer} = {
            endpoint = serverEndpoint;
            persistent-keepalive = 25;
            allowed-ips = cfg.wireguard.allowedIPs;
        };
        inherit (cfg.wireguard) ipv4 ipv6;
    };

    # NetworkManager's keyfile values are strings, ints or bools -- matching the
    # freeform ini type the upstream ensureProfiles option uses, so that e.g.
    # `dns-priority = 2` is accepted as written rather than needing quoting.
    settingsType = lib.types.attrsOf (
        lib.types.oneOf [
            lib.types.str
            lib.types.int
            lib.types.bool
        ]
    );

    extraSettings = lib.mkOption {
        type = settingsType;
        default = { };
        description = "Extra keys merged into this section, for host-local settings.";
    };
in
{
    options.technet.wifi = {
        enable = lib.mkEnableOption "the shared NetworkManager WiFi and WireGuard client profiles";

        sopsFile = lib.mkOption {
            type = lib.types.path;
            description = ''
                sops file holding networkmanager_env_file for this host -- the
                environment file supplying the PSKs and the WireGuard private key
                referenced by the profiles.
            '';
        };

        networks = lib.mkOption {
            default = { };
            description = ''
                Per-network host-side configuration. A network is only emitted as a
                profile if it appears here, so listing it is how a host opts in.
            '';
            type = lib.types.attrsOf (
                lib.types.submodule {
                    options = {
                        ipv4 = lib.mkOption {
                            type = settingsType;
                            description = "ipv4 section for this network on this host.";
                        };
                        ipv6 = lib.mkOption {
                            type = settingsType;
                            default = {
                                method = "disabled";
                            };
                            description = "ipv6 section for this network on this host.";
                        };
                        connection = extraSettings;
                        wifi = extraSettings;
                        wifi-security = extraSettings;
                    };
                }
            );
        };

        wireguard = {
            allowedIPs = lib.mkOption {
                type = lib.types.str;
                description = ''
                    allowed-ips for the server peer. `10.100.100.0/24` reaches TechNet
                    hosts only and leaves other traffic on the local link;
                    `0.0.0.0/0` routes everything through Heimdall.
                '';
            };

            ipv4 = lib.mkOption {
                type = settingsType;
                description = "ipv4 section for the tunnel, including this host's TechNet address.";
            };

            ipv6 = lib.mkOption {
                type = settingsType;
                default = {
                    method = "ignore";
                };
                description = "ipv6 section for the tunnel.";
            };

            connection = extraSettings;
            wireguard = extraSettings;
        };
    };

    config = lib.mkIf cfg.enable {
        assertions = [
            {
                assertion = lib.all (n: networks ? ${n}) (lib.attrNames cfg.networks);
                message =
                    "technet.wifi.networks has unknown network(s): "
                    + lib.concatStringsSep ", " (lib.subtractLists (lib.attrNames networks) (lib.attrNames cfg.networks))
                    + ". Known networks: "
                    + lib.concatStringsSep ", " (lib.attrNames networks)
                    + ".";
            }
        ];

        sops.secrets.networkmanager_env_file.sopsFile = cfg.sopsFile;

        networking = {
            networkmanager = {
                enable = true;
                wifi.powersave = true;
                ensureProfiles = {
                    profiles =
                        lib.mapAttrs (name: _: wifiProfile name) cfg.networks
                        // {
                            "TechNet WireGuard" = wgProfile;
                        };
                    environmentFiles = [
                        config.sops.secrets.networkmanager_env_file.path
                    ];
                };
            };

            firewall = {
                allowedUDPPorts = [ 51820 ];
                trustedInterfaces = [
                    "wireguard0"
                    "wlo1"
                ];
                checkReversePath = false;
            };
        };
    };
}
