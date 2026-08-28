# Networking #########################################################################################################################################
#
# Ragnarok's identity and addressing, and the WireGuard tunnel it dials in to Heimdall over. The initrd key handling and the tunnel recovery loop
# come from the shared module in 0-common.
#

{
    config,
    lib,
    ...
}:
{
    config = lib.mkMerge [

        # Host Identity ##############################################################################################################################
        {
            networking.hostName = "Ragnarok";
        }

        # WireGuard Tunnel ###########################################################################################################################
        {
            technet.initrdWireguard = {
                enable = true;
                sopsFile = "${config.technet.secrets.path}/wireguard.yaml";
                probe = {
                    address = "10.100.100.1";
                    interface = "wg0"; # Pinned, so recovery tests the tunnel itself rather than whatever route happens to be up
                };
                reconfigureLinks = [ "wg0" ];
            };

            networking.firewall.trustedInterfaces = [ "wg0" ];

            systemd.network.netdevs."wg0" = {
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
                        # Heimdall
                        PublicKey = "SLW2DFKk+Cf5K5KZl0OLYrEGyqTCqYHBKV2mTA3W2hQ=";
                        AllowedIPs = [ "10.100.100.0/24" ];
                        Endpoint = "bltechnet.mooo.com:51820";
                        PersistentKeepalive = 25;
                    }
                ];
            };

            systemd.network.networks."wg0" = {
                matchConfig.Name = "wg0";
                address = [ "10.100.100.6/24" ];
            };
        }

        # Ethernet ###################################################################################################################################
        {
            systemd.network.networks."end0" = {
                matchConfig.Name = "end0";
                networkConfig.DHCP = "ipv4";
                linkConfig.RequiredForOnline = "routable";
            };
        }

        # DNS ########################################################################################################################################
        {
            networking.nameservers = [
                "10.100.100.1" # Heimdall's Pi-Hole, with public resolvers behind it
                "8.8.8.8"
                "1.1.1.1"
            ];
            systemd.network.networks."wg0".dns = [ "10.100.100.1" ];
        }
    ];
}
