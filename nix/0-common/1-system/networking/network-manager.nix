{ config, lib, ... }:
{
    config = lib.mkMerge [

        # Load Wi-Fi Credentials #####################################################################################################################
        {
            sops.secrets = lib.mkIf config.networking.networkmanager.enable {
                technet_wifi_password.sopsFile = "${config.technet.secrets.commonPath}/networkmanager.yaml";
                family_home_wifi_password.sopsFile = "${config.technet.secrets.commonPath}/networkmanager.yaml";
                thor_wifi_password.sopsFile = "${config.technet.secrets.commonPath}/networkmanager.yaml";
                wireguard_private_key.sopsFile = "${config.technet.secrets.path}/networkmanager.yaml";
            };

            # NetworkManager asks nm-file-secret-agent for these when it activates a profile, so no secret is written into a keyfile.
            networking.networkmanager.ensureProfiles.secrets.entries =
                lib.mkIf config.networking.networkmanager.enable
                    [
                        {
                            matchId = "TechNet Wi-Fi";
                            matchSetting = "wifi-security";
                            key = "psk";
                            file = config.sops.secrets.technet_wifi_password.path;
                        }
                        {
                            matchId = "Digicel_5G_WiFi_5tDQ";
                            matchSetting = "wifi-security";
                            key = "psk";
                            file = config.sops.secrets.family_home_wifi_password.path;
                        }
                        {
                            matchId = "Thor Hotspot";
                            matchSetting = "wifi-security";
                            key = "psk";
                            file = config.sops.secrets.thor_wifi_password.path;
                        }
                        {
                            matchId = "TechNet Wireguard (Split Tunnel)";
                            matchSetting = "wireguard";
                            key = "private-key";
                            file = config.sops.secrets.wireguard_private_key.path;
                        }
                        {
                            matchId = "TechNet Wireguard (Full Tunnel)";
                            matchSetting = "wireguard";
                            key = "private-key";
                            file = config.sops.secrets.wireguard_private_key.path;
                        }
                    ];
        }

        # Wi-Fi Power Saving #########################################################################################################################
        {
            networking.networkmanager.wifi.powersave = true;
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
                        psk-flags = 1; # Agent-owned: served by nm-file-secret-agent, never stored in the profile
                    };
                    ipv4 = {
                        method = lib.mkDefault "auto";
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
                        psk-flags = 1; # Agent-owned: served by nm-file-secret-agent, never stored in the profile
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
                        psk-flags = 1; # Agent-owned: served by nm-file-secret-agent, never stored in the profile
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
                        autoconnect = "yes";
                    };

                    wireguard = {
                        private-key-flags = 1; # Agent-owned: served by nm-file-secret-agent, never stored in the profile
                        listen-port = "51820";
                        peer-routes = "yes";
                    };
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

                "TechNet WireGuard (Full Tunnel)" = {
                    connection = {
                        id = "TechNet Wireguard (Full Tunnel)";
                        type = "wireguard";
                        interface-name = "wireguard0";
                    };

                    wireguard = {
                        private-key-flags = 1; # Agent-owned: served by nm-file-secret-agent, never stored in the profile
                        listen-port = "51820";
                        peer-routes = "yes";
                    };
                    "wireguard-peer.SLW2DFKk+Cf5K5KZl0OLYrEGyqTCqYHBKV2mTA3W2hQ=" = {
                        endpoint = "bltechnet.mooo.com:51820";
                        persistent-keepalive = 25;
                        allowed-ips = "0.0.0.0/0";
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

    ];
}
