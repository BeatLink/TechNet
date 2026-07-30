# Networking
#
# Wireguard is a simple, high performance VPN that allows each device in the TechNet to securely connect with each other and to
# connect to the internet via a secure relay through Heimdall.
#
# The SSIDs, PSK variables and the WireGuard server's key and endpoint come from the shared module in 0-common; what is left here is
# how Odin addresses itself on each of them.
#

{ config, ... }:
{
    technet.wifi = {
        enable = true;
        sopsFile = "${config.technet.secrets.path}/networkmanager.yaml";

        networks = {
            # Static lease on the house LAN, with Heimdall as DNS.
            "TechNet Wi-Fi" = {
                connection.autoconnect-priority = "100";
                ipv4 = {
                    method = "manual";
                    addresses = "192.168.0.3/24";
                    gateway = "192.168.0.1";
                    dns = "192.168.0.2";
                };
            };
            "Digicel_5G_WiFi_5tDQ" = {
                connection.autoconnect-priority = "100";
                ipv4.method = "auto";
            };
            # Lower priority so the phone's hotspot is a fallback, not a preference.
            "Thor Hotspot" = {
                connection.autoconnect-priority = "50";
                ipv4.method = "auto";
            };
        };

        wireguard = {
            # Split tunnel: reach TechNet hosts over the VPN, everything else direct.
            allowedIPs = "10.100.100.0/24";
            ipv4 = {
                method = "manual";
                addresses = "10.100.100.2/24";
                dns = "10.100.100.1;";
                dns-priority = 2;
            };
        };
    };

    networking = {
        hostName = "Odin"; # Sets hostname
        hostId = "ee42298c";
    };
}
