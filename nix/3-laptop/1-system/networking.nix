# Networking
#
# Wireguard is a simple, high performance VPN that allows each device in the TechNet to securely connect with each other and to
# connect to the internet via a secure relay through Heimdall. Every NetworkManager profile Odin uses is written out in full below.
#

{ config, ... }:
{
    sops.secrets.networkmanager_env_file.sopsFile = "${config.technet.secrets.path}/networkmanager.yaml";

    networking = {
        hostName = "Odin"; # Sets hostname

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
                    # Static lease on the house LAN, with Heimdall as DNS.
                    "TechNet Wi-Fi" = {
                        connection = {
                            id = "TechNet Wi-Fi";
                            type = "wifi";
                            autoconnect-priority = "100";
                        };
                        wifi = {
                            ssid = "TechNet Wi-Fi";
                            # The SSID is not broadcast, so NetworkManager has to probe for it by name.
                            hidden = true;
                            # 5GHz only, to keep the shared MediaTek radio off the 2.4GHz keyboard dongle's band.
                            band = "a";
                        };
                        wifi-security = {
                            key-mgmt = "wpa-psk";
                            psk = "$TECHNET_WIFI_PASSWORD";
                        };
                        ipv4 = {
                            method = "manual";
                            addresses = "192.168.0.3/24";
                            gateway = "192.168.0.1";
                            dns = "192.168.0.2";
                        };
                        ipv6.method = "disabled";
                    };

                    "Digicel_5G_WiFi_5tDQ" = {
                        connection = {
                            id = "Digicel_5G_WiFi_5tDQ";
                            type = "wifi";
                            autoconnect-priority = "100";
                        };
                        wifi.ssid = "Digicel_5G_WiFi_5tDQ";
                        wifi-security = {
                            key-mgmt = "wpa-psk";
                            psk = "$FAMILY_HOME_WIFI_PASSWORD";
                        };
                        ipv4.method = "auto";
                        ipv6.method = "disabled";
                    };

                    # Lower priority so the phone's hotspot is a fallback, not a preference.
                    "Thor Hotspot" = {
                        connection = {
                            id = "Thor Hotspot";
                            type = "wifi";
                            autoconnect-priority = "50";
                        };
                        wifi.ssid = "Thor";
                        wifi-security = {
                            key-mgmt = "wpa-psk";
                            psk = "$THOR_WIFI_PASSWORD";
                        };
                        ipv4.method = "auto";
                        ipv6.method = "disabled";
                    };

                    "TechNet WireGuard" = {
                        connection = {
                            id = "TechNet Wireguard";
                            type = "wireguard";
                            interface-name = "wireguard0";
                        };
                        wireguard.private-key = "$WIREGUARD_PRIVATE_KEY";
                        # Split tunnel: reach TechNet hosts over the VPN, everything else direct.
                        "wireguard-peer.SLW2DFKk+Cf5K5KZl0OLYrEGyqTCqYHBKV2mTA3W2hQ=" = {
                            endpoint = "bltechnet.mooo.com:51820";
                            persistent-keepalive = 25;
                            allowed-ips = "10.100.100.0/24";
                        };
                        ipv4 = {
                            method = "manual";
                            addresses = "10.100.100.2/24";
                            dns = "10.100.100.1;";
                            dns-priority = 2;
                        };
                        ipv6.method = "ignore";
                    };

                    "Thor USB" = {
                        connection = {
                            id = "Thor USB";
                            type = "ethernet";
                            autoconnect = "true";
                        };
                        ethernet.mac-address = "02:00:00:00:00:02";
                        ipv4 = {
                            method = "manual";
                            addresses = "10.100.101.2/30";
                            never-default = "true";
                            dns-search = "";
                        };
                        ipv6.method = "link-local";
                    };
                };
            };
        };
    };
}
