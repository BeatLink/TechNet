# Networking ##########################################################################################################################
#
# Wireguard is a simple, high performance VPN that allows each device in the TechNet to securely connect with each other and to 
# connect to the internet via a secure relay through Heimdall. It also allows the server to be accessed during boot for remote decryption
# 
# The systemd.network configuration is used over networking or networkmanager as it has support for wireguard in initrd. Also, Systemd
# doesn't really separate networking between initrd and the main system so all networking is configured here. Subsequently, changing
# network settings will usually require a restart (since the wireguard private key can only really be accessed from initrd)
#
######################################################################################################################################
{ config, lib, pkgs, ... }:
{
    networking = {
        hostName = "Heimdall";                                          # Sets hostname
        nameservers = [ "10.100.100.1" "8.8.8.8" "1.1.1.1" ];           # Sets up dns
        firewall = {
            allowedUDPPorts = [ 51820 ];                                # Allows Wireguard on Firewall
            trustedInterfaces = [ "wireguard0" ];
            checkReversePath = "loose";                                 # Needed for wireguard`
        };
    };
    sops.secrets.wireguard_private_key.sopsFile = ../secrets.yaml;
    boot = {
        #kernel.sysctl."net.ipv4.ip_forward" = 1;                        # Enables routing between peers for wireguard
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
                    netdevs."01-wireguard" = {
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
                                # Laptop
                                PublicKey = "WlTdwgmdSvXTGjB+kaOkZEV9vyOk/fKELv3IkRdJOAE=";
                                AllowedIPs = ["10.100.100.2/32"];
                            }
                            {
                                # Tablet
                                PublicKey = "JruIjfXKUUz75fTnwgPfJ/4vBixSAgAodj9NwVAoyl8=";
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
                            {
                                # Work Server
                                PublicKey = "e4NiZgFqDoddb3RDNLaLCNyQsZR9sH8SaNIoB+c5HAQ=";
                                AllowedIPs = ["10.100.100.50/32"];
                            }
                        ];
                    };
                    networks = {
                        "01-enp2s0f1" = {
                            matchConfig.Name = "enp2s0f1";
                            address = [ "192.168.0.2/24"];
                            gateway = ["192.168.0.1"];
                            linkConfig.RequiredForOnline = "routable";
                            #networkConfig = {                           # Enables forwarding of VPN traffic to the internet
                            #    IPv4Forwarding = true;
                            #    IPMasquerade = "ipv4";
                            #};
                        };
                        "01-wireguard" = {
                            matchConfig.Name = "wireguard0";
                            address = ["10.100.100.1/24"];
                            #networkConfig = {                           # Enables forwarding of VPN traffic to the internet
                            #    IPv4Forwarding = true;
                            #};
                        };
                    };
                };
            };
        };
    };
}
