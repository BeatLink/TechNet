# Networking ##########################################################################################################################    
# The systemd.network configuration is used over networking or networkmanager as it has support for wireguard in initrd. Also, Systemd 
# doesn't really separate networking between initrd and the main system so all networking is configured here. Subsequently, changing
# network settings will usually require a restart (since the wireguard private key can only really be accessed from initrd)
######################################################################################################################################
{ config, lib, pkgs, ... }:
{
    sops.age.sshKeyPaths = [ "/persistent/etc/ssh/ssh_host_ed25519_key" ];
    sops.secrets.wireguard_private_key.sopsFile = ./secrets.yaml;
    networking = {
        hostName = "Heimdall";                                          # Sets hostname
        nameservers = [ "10.100.100.1" "8.8.8.8" "1.1.1.1" ];           # Sets up dns
        firewall = {
            checkReversePath = "loose";                                 # Needed for wireguard
            allowedUDPPorts = [ 51820 ];                                # Allows Wireguard on Firewall
        };
    };
    boot = {
        kernel.sysctl."net.ipv4.ip_forward" = 1;                        # Enables routing between peers for wireguard
        initrd = {
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
                    netdevs."01-wireguard" = {
                        netdevConfig = {
                            Kind = "wireguard";
                            Name = "wg0";
                            MTUBytes = "1280";
                        };
                        wireguardConfig = {
                            PrivateKeyFile = /wireguard_private_key;
                            ListenPort = 51820;
                        };
                        wireguardPeers = [
                            {
                                # Laptop
                                PublicKey = "WlTdwgmdSvXTGjB+kaOkZEV9vyOk/fKELv3IkRdJOAE=";
                                AllowedIPs = ["10.100.100.2/32"];
                            }
                            {
                                # Tablet 
                                PublicKey = "LneSvdXvU9Y/+DROhb+qVGgxkjpT9KtW2ifMADDJ0HM=";
                                AllowedIPs = ["10.100.100.3/32"];
                            }
                            {
                                # Phone
                                PublicKey = "/TCFjby/XxSkAQxuWcL5Kv5ggOlYJtloyU+z1I8wGWs=";
                                AllowedIPs = ["10.100.100.4/32"];
                            }
                            {
                                # Backup Server
                                PublicKey = "rntfoR0iPjL90MhrwIFOVI0hSoZ8hHj8A512Q4+1hk4=";
                                AllowedIPs = ["10.100.100.5/32"];
                            }
                        ];
                    };
                    networks = {
                        "01-enp2s0f1" = {
                            matchConfig.Name = "enp2s0f1";
                            address = [ "192.168.0.2/24"];
                            gateway = ["192.168.0.1"];
                            linkConfig.RequiredForOnline = "routable";
                        };
                        "01-wireguard" = {
                            matchConfig.Name = "wg0";
                            address = ["10.100.100.1/24"];
                            networkConfig = {                           # Enables forwarding of VPN traffic to the internet
                                IPMasquerade = "ipv4";
                                IPv4Forwarding = true;
                            };
                        };
                    };               
                };
            };
        };
    };
}