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
        useDHCP = lib.mkDefault true;                                               # Enables DHCP
    };
    sops.secrets.wireguard_private_key = {
        sopsFile = ../secrets/secrets.yaml;
    };
    systemd.network = {
        enable = true;
        netdevs."01-wireguard" = {                                                  # Adds the wireguard virtual network device
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
                    AllowedIPs = ["10.100.100.0/24"];
                    Endpoint = "72.252.37.234:51820";
                    PersistentKeepalive = 15;
                }
            ];
        };
        networks = {                                                                # Sets up the Ethernet Network
            "01-end0" = {
                matchConfig.Name = "end0";
                address = [ "192.168.100.254/24"];
                gateway = ["192.168.100.1"];
                linkConfig.RequiredForOnline = "routable";
            };                                                                      # Sets up the Wireguard Network
            "01-wireguard" = {
                matchConfig.Name = "wg0";
                address = ["10.100.100.5/24"];
            };
        };
    };
}
