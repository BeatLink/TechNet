# Networking
#
# This file configures wireguard and networking settings
#
# The initrd wireguard key handling and the tunnel recovery loop come from the
# shared module in 0-common; what is left here is Ragnarok-specific -- its
# identity, its addressing and its single peer (the server).
#

{ config, inputs, ... }:
{
    technet.initrdWireguard = {
        enable = true;
        sopsFile = "${config.technet.secrets.path}/wireguard.yaml";
        # Ragnarok is a client, so the tunnel itself is what has to work. Force the
        # probe out of wg0 rather than letting routing pick a path.
        probe = {
            address = "10.100.100.1";
            interface = "wg0";
        };
        reconfigureLinks = [ "wg0" ];
    };

    networking = {
        # Sets the hostName
        hostName = "Ragnarok";

        # Sets the Host ID for ZFS
        hostId = "bed2ee51";

        # Sets up DNS. The server's Pi-Hole is the main DNS with Google and Cloudfare as backup
        nameservers = [
            "10.100.100.1"
            "8.8.8.8"
            "1.1.1.1"
        ];

        # Sets the Wireguard interface as trusted in the firewall
        firewall.trustedInterfaces = [ "wg0" ];
    };

    systemd.network = {
        netdevs."wg0" = {
            netdevConfig = {
                Kind = "wireguard";
                Name = "wg0";
            };
            wireguardConfig = {
                PrivateKeyFile = config.sops.secrets.wireguard_private_key.path;
                ListenPort = 51820;
            };
            wireguardPeers = [
                {
                    # Server
                    PublicKey = "SLW2DFKk+Cf5K5KZl0OLYrEGyqTCqYHBKV2mTA3W2hQ=";
                    AllowedIPs = [ "10.100.100.0/24" ];
                    Endpoint = "bltechnet.mooo.com:51820";
                    PersistentKeepalive = 25;
                }
            ];
        };
        networks = {
            "end0" = {
                matchConfig.Name = "end0";
                networkConfig.DHCP = "ipv4";
                linkConfig.RequiredForOnline = "routable";
            };
            "wg0" = {
                matchConfig.Name = "wg0";
                address = [ "10.100.100.6/24" ];
                dns = [ "10.100.100.1" ];
            };
        };
    };
}
