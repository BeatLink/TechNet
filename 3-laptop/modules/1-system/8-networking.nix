# Networking ##########################################################################################################################
#
# Wireguard is a simple, high performance VPN that allows each device in the TechNet to securely connect with each other and to 
# connect to the internet via a secure relay through Heimdall. 
#
######################################################################################################################################
{ config, ... }:
{
    sops.secrets.networkmanager_env_file.sopsFile = ../../secrets.yaml;
    networking = {
        hostName = "Odin";                                              # Sets hostname
        hostId = "ee42298c";
        networkmanager = {
            enable = true;
            wifi.powersave = true;
            ensureProfiles = {
                profiles = {
                    "TechNet Wi-Fi" = {
                        connection = {
                            id = "TechNet Wi-Fi";
                            permissions = "";
                            type = "wifi";
                        };
                        ipv4 = {
                            dns = "10.100.100.1";
                            dns-search = "";
                            method = "auto";
                        };
                        ipv6 = {
                            addr-gen-mode = "stable-privacy";
                            dns-search = "";
                            method = "auto";
                        };
                        wifi = {
                            mac-address-blacklist = "";
                            mode = "infrastructure";
                            ssid = "TechNet Wi-Fi";
                        };
                        wifi-security = {
                            auth-alg = "open";
                            key-mgmt = "wpa-psk";
                            psk = "$TECHNET_WIFI_PASSWORD";
                        };
                    };
                    "Digicel_5G_WiFi_5tDQ" = {
                        connection = {
                            id = "Digicel_5G_WiFi_5tDQ";
                            permissions = "";
                            type = "wifi";
                        };
                        ipv4 = {
                            dns = "10.100.100.1";
                            dns-search = "";
                            method = "auto";
                        };
                        ipv6 = {
                            addr-gen-mode = "stable-privacy";
                            dns-search = "";
                            method = "auto";
                        };
                        wifi = {
                            mac-address-blacklist = "";
                            mode = "infrastructure";
                            ssid = "Digicel_5G_WiFi_5tDQ";
                        };
                        wifi-security = {
                            auth-alg = "open";
                            key-mgmt = "wpa-psk";
                            psk = "$FAMILY_HOME_WIFI_PASSWORD";
                        };
                    };
                    "TechNet WireGuard" = {
                        connection = {
                            id = "TechNet Wireguard";
                            type = "wireguard";
                            permissions = "";
                            interface-name = "wireguard0";
                            autoconnect = "yes";
                        };
                        wireguard = {
                            listen-port = "51820";
                            peer-routes = "yes";
                            private-key = "$WIREGUARD_PRIVATE_KEY";
                        };
                        "wireguard-peer.SLW2DFKk+Cf5K5KZl0OLYrEGyqTCqYHBKV2mTA3W2hQ=" = {
                            endpoint = "72.252.37.234:51820";
                            persistent-keepalive = 25;
                            allowed-ips = "0.0.0.0/0";
                        };
                        ipv4 = {
                            method = "manual";
                            dns-search = "";
                            addresses = "10.100.100.2/24" ;
                        };
                        ipv6 = {
                            method = "ignore";
                        };
                    };
                };
                environmentFiles = [
                    config.sops.secrets.networkmanager_env_file.path
                ];
            };
        };
        firewall = {
            allowedUDPPorts = [ 51820 ];                                # Allows Wireguard on Firewall
            checkReversePath = false; 
        };
    };
}

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;