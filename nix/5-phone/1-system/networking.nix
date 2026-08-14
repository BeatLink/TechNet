# Networking
#
# Wireguard is a simple, high performance VPN that allows each device in the TechNet to securely connect with each other and to
# connect to the internet via a secure relay through Heimdall.
#
# The SSIDs, PSK variables and the WireGuard server's key and endpoint come from the shared module in 0-common; what is left here is
# how Thor addresses itself on each of them.
#
# Thor's profiles carry a few extra keys the laptop's do not (permissions, dns-search, mode, mac-address-blacklist, auth-alg). These
# came from profiles originally written on-device by NetworkManager itself, and are kept so the generated keyfiles stay byte-identical
# to what the phone is already running.
#

{ config, ... }:
let
    # Repeated verbatim on each of Thor's wifi profiles.
    wifiExtras = {
        connection.permissions = "";
        wifi = {
            mac-address-blacklist = "";
            mode = "infrastructure";
        };
        wifi-security.auth-alg = "open";
    };

    # DHCP on the link, leaving Pi-hole to the tunnel profile so a dead tunnel never outranks the link's own resolver.
    dhcpNoSearchDomain = {
        ipv4 = {
            dns-search = "";
            method = "auto";
        };
        ipv6 = {
            addr-gen-mode = "stable-privacy";
            dns-search = "";
            method = "auto";
        };
    };
in
{
    technet.wifi = {
        enable = true;
        sopsFile = "${config.technet.secrets.path}/networkmanager.yaml";

        networks = {
            "TechNet Wi-Fi" = wifiExtras // dhcpNoSearchDomain;
            "Digicel_5G_WiFi_5tDQ" = wifiExtras // dhcpNoSearchDomain;
            "Thor Hotspot" = wifiExtras // dhcpNoSearchDomain;
        };

        wireguard = {
            # Full tunnel: the phone routes everything through Heimdall.
            allowedIPs = "0.0.0.0/0";
            connection = {
                permissions = "";
                autoconnect = "yes";
            };
            wireguard = {
                listen-port = "51820";
                peer-routes = "yes";
            };
            # DNS rides the tunnel rather than the link below it, so .technet resolves on mobile data as well as on the wifi
            ipv4 = {
                method = "manual";
                dns = "10.100.100.1";
                # Low but positive, so Pi-hole is asked first for .technet while the link's own resolver stays listed behind it: a negative value is exclusive and suppresses that fallback, leaving nothing able to resolve the peer endpoint once the tunnel drops
                dns-priority = 2;
                dns-search = "";
                addresses = "10.100.100.4/24";
            };
        };
    };

    networking = {
        hostName = "Thor"; # Sets the hostName

        networkmanager.ensureProfiles.profiles."USB Gadget" = {
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
}
