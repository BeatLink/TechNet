# Networking
#
# Wireguard is a simple, high performance VPN that allows each device in the TechNet to securely connect with each other and to
# connect to the internet via a secure relay through Heimdall.
#

{ config, inputs, ... }:
{
    sops.secrets.networkmanager_env_file.sopsFile = "${inputs.self}/secrets/3-laptop/networkmanager.yaml";
    networking = {
        hostName = "Odin"; # Sets hostname
        hostId = "ee42298c";
        networkmanager = {
            enable = true;
            wifi.powersave = true;
            ensureProfiles = {
                profiles = {
                    "TechNet Wi-Fi (Pi-Hole)" = {
                        connection = {
                            id = "TechNet Wi-Fi (Pi-Hole)";
                            type = "wifi";
                            autoconnect-priority = "100";
                        };
                        wifi = {
                            ssid = "TechNet Wi-Fi";
                        };
                        wifi-security = {
                            key-mgmt = "wpa-psk";
                            psk = "$TECHNET_WIFI_PASSWORD";
                        };
                        ipv4 = {
                            method = "auto";
                            dns = "10.100.100.1";
                        };
                        ipv6 = {
                            method = "disabled";
                        };
                    };
                    "TechNet Wi-Fi (No DNS)" = {
                        connection = {
                            id = "TechNet Wi-Fi (No DNS)";
                            type = "wifi";
                            autoconnect = "no";
                        };
                        wifi = {
                            ssid = "TechNet Wi-Fi";
                        };
                        wifi-security = {
                            key-mgmt = "wpa-psk";
                            psk = "$TECHNET_WIFI_PASSWORD";
                        };
                        ipv4 = {
                            method = "auto";
                        };
                        ipv6 = {
                            method = "disabled";
                        };
                    };
                    "Digicel_5G_WiFi_5tDQ" = {
                        connection = {
                            id = "Digicel_5G_WiFi_5tDQ";
                            type = "wifi";
                            autoconnect-priority = "100";
                        };
                        ipv4 = {
                            dns = "10.100.100.1";
                            method = "auto";
                        };
                        ipv6 = {
                            method = "disabled";
                        };
                        wifi = {
                            ssid = "Digicel_5G_WiFi_5tDQ";
                        };
                        wifi-security = {
                            key-mgmt = "wpa-psk";
                            psk = "$FAMILY_HOME_WIFI_PASSWORD";
                        };
                    };
                    "TechNet WireGuard" = {
                        connection = {
                            id = "TechNet Wireguard";
                            type = "wireguard";
                            interface-name = "wireguard0";
                        };
                        wireguard = {
                            private-key = "$WIREGUARD_PRIVATE_KEY";
                        };
                        "wireguard-peer.SLW2DFKk+Cf5K5KZl0OLYrEGyqTCqYHBKV2mTA3W2hQ=" = {
                            endpoint = "bltechnet.mooo.com:51820";
                            persistent-keepalive = 25;
                            allowed-ips = "0.0.0.0/0";
                        };
                        ipv4 = {
                            method = "manual";
                            addresses = "10.100.100.2/24";
                        };
                        ipv6 = {
                            method = "ignore";
                        };
                    };
                    "Thor Hotspot" = {
                        connection = {
                            id = "Thor Hotspot";
                            type = "wifi";
                            autoconnect-priority = "50";
                        };
                        ipv4 = {
                            dns = "10.100.100.1";
                            method = "auto";
                        };
                        ipv6 = {
                            method = "disabled";
                        };
                        wifi = {
                            ssid = "Thor";
                        };
                        wifi-security = {
                            key-mgmt = "wpa-psk";
                            psk = "$THOR_WIFI_PASSWORD";
                        };
                    };
                };
                environmentFiles = [
                    config.sops.secrets.networkmanager_env_file.path
                ];
            };
        };
        firewall = {
            allowedUDPPorts = [ 51820 ]; # Allows Wireguard on Firewall
            # allowedTCPPorts = [ ... ];
            trustedInterfaces = [
                "wireguard0"
                "wlo1"
            ];
            checkReversePath = false;
        };
    };
}
