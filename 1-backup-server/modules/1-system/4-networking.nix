# Networking ##############################################################################################################################
#
# This file configures wireguard and networking settings
#
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    networking = {
        hostName = "Ragnarok";                                                      # Sets the hostName
        useNetworkd = true;                                                         # Use Systemd-Networkd
        firewall.trustedInterfaces = [ "wireguard0" ];
    };
    sops.secrets.wireguard_private_key = {
        sopsFile = ../../secrets/secrets.yaml;
        group = config.users.users.systemd-network.group;
        mode = "0640";
        reloadUnits = [ "systemd-networkd.service" ];
    };
    systemd.network = {
        enable = true;
        netdevs."01-wireguard" = {                                                  # Adds the wireguard virtual network device
            netdevConfig = {
                Kind = "wireguard";
                Name = "wireguard0";
            };
            wireguardConfig = {
                PrivateKeyFile = config.sops.secrets.wireguard_private_key.path;
                ListenPort = 51820;
            };        
            wireguardPeers = [
                {
                    # Server
                    PublicKey = "SLW2DFKk+Cf5K5KZl0OLYrEGyqTCqYHBKV2mTA3W2hQ=";
                    AllowedIPs = ["10.100.100.0/24"];
                    Endpoint = "72.252.37.234:51820";
                    PersistentKeepalive = 15;
                }
            ];
        };
        networks = {                                                                # Sets up the Ethernet Network
            "01-eth0" = {
                matchConfig.Name = "eth0";
                networkConfig.DHCP = "ipv4";
                linkConfig.RequiredForOnline = "routable";
            };                                                                      # Sets up the Wireguard Network
            "01-wireguard" = {
                matchConfig.Name = "wireguard0";
                address = ["10.100.100.5/24"];
            };
        };
    };
}
