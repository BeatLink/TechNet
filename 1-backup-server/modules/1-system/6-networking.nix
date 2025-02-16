# Networking ##############################################################################################################################
#
# This file configures wireguard and networking settings
#
###########################################################################################################################################

{ config, ... }:
{
    networking = {
        hostName = "Ragnarok";                                                      # Sets the hostName
        hostId = "bed2ee51";
        useNetworkd = true;                                                         # Use Systemd-Networkd
        firewall.trustedInterfaces = [ "wireguard0" ];
    };
    sops.secrets.wireguard_private_key.sopsFile = ../../secrets.yaml;
    boot = {
        initrd = {
            availableKernelModules = [
                "wireguard"                                             # Needed for wireguard in initrd for remote LUKS unlocking
                "r8169"                                                 # Ethernet NIC driver
            ];
            secrets = {                                                 # Sops doesn't work in initrd so we use boot.initrd.secrets
                "/wireguard_private_key" = config.sops.secrets.wireguard_private_key.path;
            };
            systemd = {
                services.fix_wireguard_key_perms = {            # The Wireguard privatekey must be owned by systemd-network to be used.
                    description = "Set permissions for wireguard private key";
                    wantedBy = [
                        "initrd.target"
                    ];
                    after = [
                        "initrd-nixos-copy-secrets.service"
                    ];
                    before = [
                        "systemd-networkd.service"
                    ];
                    unitConfig.DefaultDependencies = "no";
                    serviceConfig.Type = "oneshot";
                    script = ''
                        chown systemd-network:systemd-network /wireguard_private_key
                    '';
                };
                network = {
                    enable = true;
                    netdevs."01-wireguard" = {                                                  # Adds the wireguard virtual network device
                        netdevConfig = {
                            Kind = "wireguard";
                            Name = "wireguard0";
                        };
                        wireguardConfig = {
                            PrivateKeyFile = /wireguard_private_key;
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
                            dns = [ "10.100.100.1" ];                                           # Sets up dns
                            networkConfig.DHCP = "ipv4";
                            linkConfig.RequiredForOnline = "routable";
                        };                                                                      # Sets up the Wireguard Network
                        "01-wireguard" = {
                            matchConfig.Name = "wireguard0";
                            dns = [ "10.100.100.1" ];                                           # Sets up dns
                            address = ["10.100.100.5/24"];
                        };
                    };
                };
            };
        };
    };
}
