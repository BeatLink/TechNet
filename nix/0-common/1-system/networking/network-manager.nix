{ config, lib, ... }:
{
    config = lib.mkMerge [

        # Load Wi-Fi Credentials #####################################################################################################################
        {
            sops.secrets.networkmanager_env_file.sopsFile = "${config.technet.secrets.path}/networkmanager.yaml";
            networking.networkmanager.ensureProfiles.environmentFiles = [
                config.sops.secrets.networkmanager_env_file.path
            ];
        }

        # Declares Known Profiles ####################################################################################################################
        {
            networking.networkmanager.ensureProfiles.profiles = {

                # Home Wi-Fi -------------------------------------------------------------------------------------------------------------------------
                "TechNet Wi-Fi" = {
                    connection = {
                        id = "TechNet Wi-Fi";
                        type = "wifi";
                        autoconnect-priority = "100";
                    };
                    wifi = {
                        ssid = "TechNet Wi-Fi";
                        hidden = true;
                        band = lib.mkDefault "a";
                    };
                    wifi-security = {
                        key-mgmt = "wpa-psk";
                        psk = "$TECHNET_WIFI_PASSWORD";
                    };
                    ipv4 = {
                        gateway = "192.168.0.1";
                        dns = "192.168.0.2";
                    };
                    ipv6.method = "disabled";
                };

                # Family Wi-Fi -----------------------------------------------------------------------------------------------------------------------
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

                # Mobile Hotspot ---------------------------------------------------------------------------------------------------------------------
                "Thor Hotspot" = {
                    connection = {
                        id = "Thor Hotspot";
                        type = "wifi";
                        autoconnect-priority = "50"; # Fallback with the two above preferred
                    };
                    wifi.ssid = "Thor";
                    wifi-security = {
                        key-mgmt = "wpa-psk";
                        psk = "$THOR_WIFI_PASSWORD";
                    };
                    ipv4.method = "auto";
                    ipv6.method = "disabled";
                };

            };

        }

        # Setup Wireguard NM PRofile #################################################################################################################
        {
            networking.networkmanager.ensureProfiles.profiles = {
                "TechNet WireGuard (Split Tunnel)" = {
                    connection = {
                        id = "TechNet Wireguard (Split Tunnel)";
                        type = "wireguard";
                        interface-name = "wireguard0";
                    };

                    wireguard.private-key = "$WIREGUARD_PRIVATE_KEY";
                    "wireguard-peer.SLW2DFKk+Cf5K5KZl0OLYrEGyqTCqYHBKV2mTA3W2hQ=" = {
                        endpoint = "bltechnet.mooo.com:51820";
                        persistent-keepalive = 25;
                        allowed-ips = "10.100.100.0/24";
                    };
                    ipv4 = {
                        method = "manual";
                        dns = "10.100.100.1;";
                        dns-priority = 2;
                    };
                    ipv6.method = "ignore";
                };
            };
        }

        # Wi-Fi Power Saving #########################################################################################################################
        {
            networking.networkmanager.wifi.powersave = true;
        }

    ];
}
