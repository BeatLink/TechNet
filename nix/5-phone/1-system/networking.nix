# Networking
#
# Wireguard is a simple, high performance VPN that allows each device in the TechNet to securely connect with each other and to
# connect to the internet via a secure relay through Heimdall. Every NetworkManager profile Thor uses is written out in full below,
# including the keys NetworkManager itself wrote on-device (permissions, dns-search, mode, mac-address-blacklist, auth-alg), which
# are kept so the generated keyfiles stay byte-identical to what the phone is already running.
#

{ config, ... }:
{
    sops.secrets.networkmanager_env_file.sopsFile = "${config.technet.secrets.path}/networkmanager.yaml";

    networking = {
        hostName = "Thor"; # Sets the hostName

        firewall = {
            allowedUDPPorts = [ 51820 ];
            trustedInterfaces = [
                "wireguard0"
                "wlo1"
            ];
            checkReversePath = false;
        };

        networkmanager = {
            enable = true;
            wifi.powersave = true;

            ensureProfiles = {
                environmentFiles = [
                    config.sops.secrets.networkmanager_env_file.path
                ];

                profiles = {
                    # DHCP on the link, leaving Pi-hole to the tunnel profile so a dead tunnel never outranks the link's own resolver.
                    "TechNet Wi-Fi" = {
                        connection = {
                            id = "TechNet Wi-Fi";
                            type = "wifi";
                            permissions = "";
                        };
                        wifi = {
                            ssid = "TechNet Wi-Fi";
                            # The SSID is not broadcast, so NetworkManager has to probe for it by name.
                            hidden = true;
                            mode = "infrastructure";
                            mac-address-blacklist = "";
                        };
                        wifi-security = {
                            key-mgmt = "wpa-psk";
                            psk = "$TECHNET_WIFI_PASSWORD";
                            auth-alg = "open";
                        };
                        ipv4 = {
                            method = "auto";
                            dns-search = "";
                        };
                        ipv6 = {
                            method = "auto";
                            addr-gen-mode = "stable-privacy";
                            dns-search = "";
                        };
                    };

                    "Digicel_5G_WiFi_5tDQ" = {
                        connection = {
                            id = "Digicel_5G_WiFi_5tDQ";
                            type = "wifi";
                            permissions = "";
                        };
                        wifi = {
                            ssid = "Digicel_5G_WiFi_5tDQ";
                            mode = "infrastructure";
                            mac-address-blacklist = "";
                        };
                        wifi-security = {
                            key-mgmt = "wpa-psk";
                            psk = "$FAMILY_HOME_WIFI_PASSWORD";
                            auth-alg = "open";
                        };
                        ipv4 = {
                            method = "auto";
                            dns-search = "";
                        };
                        ipv6 = {
                            method = "auto";
                            addr-gen-mode = "stable-privacy";
                            dns-search = "";
                        };
                    };

                    "Thor Hotspot" = {
                        connection = {
                            id = "Thor Hotspot";
                            type = "wifi";
                            permissions = "";
                        };
                        wifi = {
                            ssid = "Thor";
                            mode = "infrastructure";
                            mac-address-blacklist = "";
                        };
                        wifi-security = {
                            key-mgmt = "wpa-psk";
                            psk = "$THOR_WIFI_PASSWORD";
                            auth-alg = "open";
                        };
                        ipv4 = {
                            method = "auto";
                            dns-search = "";
                        };
                        ipv6 = {
                            method = "auto";
                            addr-gen-mode = "stable-privacy";
                            dns-search = "";
                        };
                    };

                    "TechNet WireGuard" = {
                        connection = {
                            id = "TechNet Wireguard";
                            type = "wireguard";
                            interface-name = "wireguard0";
                            autoconnect = "yes";
                            permissions = "";
                        };
                        wireguard = {
                            private-key = "$WIREGUARD_PRIVATE_KEY";
                            listen-port = "51820";
                            peer-routes = "yes";
                        };
                        # Full tunnel: the phone routes everything through Heimdall.
                        "wireguard-peer.SLW2DFKk+Cf5K5KZl0OLYrEGyqTCqYHBKV2mTA3W2hQ=" = {
                            endpoint = "bltechnet.mooo.com:51820";
                            persistent-keepalive = 25;
                            allowed-ips = "0.0.0.0/0";
                        };
                        # DNS rides the tunnel rather than the link below it, so .technet resolves on mobile data as well as on the wifi
                        ipv4 = {
                            method = "manual";
                            addresses = "10.100.100.4/24";
                            dns = "10.100.100.1";
                            # Low but positive, so Pi-hole is asked first for .technet while the link's own resolver stays listed behind it: a negative value is exclusive and suppresses that fallback, leaving nothing able to resolve the peer endpoint once the tunnel drops
                            dns-priority = 2;
                            dns-search = "";
                        };
                        ipv6.method = "ignore";
                    };

                    "USB Gadget" = {
                        connection = {
                            id = "USB Gadget";
                            type = "ethernet";
                            interface-name = "usb0";
                            autoconnect = "true";
                            permissions = "";
                        };
                        ethernet.cloned-mac-address = "preserve";
                        ipv4 = {
                            method = "manual";
                            addresses = "10.100.101.1/30";
                            never-default = "true";
                            dns-search = "";
                        };
                        ipv6 = {
                            method = "link-local";
                            addr-gen-mode = "stable-privacy";
                            dns-search = "";
                        };
                    };
                };
            };
        };
    };
}
