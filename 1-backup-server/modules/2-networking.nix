# Networking ------------------------------------------------------------------------------------------------------------------------------------

{ config, lib, pkgs, ... }:
{
    networking.hostname = "Ragnarok";
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    sops.secrets.wireguard_private_key = {
        sopsFile = ../secrets.yaml;
    };
    systemd.network = {
        enable = true;
        netdevs."01-wireguard" = {
            netdevConfig = {
                Kind = "wireguard";
                Name = "wg0";
                MTUBytes = "1500";
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
        networks = {
            "01-end0" = {
                matchConfig.Name = "end0";
                address = [ "192.168.100.254/24"];
                gateway = ["192.168.100.1"];
                linkConfig.RequiredForOnline = "routable";
            };
            "01-wireguard" = {
                matchConfig.Name = "wg0";
                address = ["10.100.100.5/24"];
            };
        };
    };
}
