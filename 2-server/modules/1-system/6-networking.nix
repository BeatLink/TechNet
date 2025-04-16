# Networking ##########################################################################################################################
#
# Wireguard is a simple, high performance VPN that allows each device in the TechNet to securely connect with each other and to 
# connect to the internet via a secure relay through Heimdall. It also allows the server to be accessed during boot for remote decryption
# 
# The systemd.network configuration is used over networking or networkmanager as it has support for wireguard in initrd. Also, Systemd
# doesn't really separate networking between initrd and the main system so all networking is configured here. Subsequently, changing
# network settings will usually require a restart (since the wireguard private key can only really be accessed from initrd)
#
# This link helped a lot with getting this configuration working: https://flo-the.dev/posts/wireguard/
#
######################################################################################################################################
{ config, ... }:
{
    networking = {
        hostName = "Heimdall";                                          # Sets hostname
        hostId = "e5aa3553";
        nameservers = [ "8.8.8.8" "1.1.1.1" "127.0.0.1" ];              # Sets up dns
        firewall = {
            allowedUDPPorts = [ 51820 ];                                # Allows Wireguard on Firewall
            extraCommands = ''
            iptables -t nat -A POSTROUTING -o enp2s0f1 -j MASQUERADE
            ip46tables -A FORWARD -i enp2s0f1 -o wireguard0 -j ACCEPT
            ip46tables -A FORWARD -i wireguard0 -j ACCEPT
            '';
            #flush the chain then remove it
            extraStopCommands = ''
            iptables -t nat -D POSTROUTING -o enp2s0f1 -j MASQUERADE
            ip46tables -D FORWARD -i enp2s0f1 -o wireguard0 -j ACCEPT
            ip46tables -D FORWARD -i wireguard0 -j ACCEPT
            '';
        };
    };
    sops.secrets.wireguard_private_key.sopsFile = ../../secrets.yaml;
    boot = {
        kernel.sysctl."net.ipv4.conf.all.forwarding" = true;            # Enables routing between peers for wireguard
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
                                PersistentKeepalive = 15;
                            }
                            {
                                # Tablet
                                PublicKey = "rvOxr8WYaQRMHI8Ic0Td6mBOTwkI9U842AHkLrZDDkQ=";
                                AllowedIPs = ["10.100.100.3/32"];
                                PersistentKeepalive = 15;
                            }
                            {
                                # Phone
                                PublicKey = "/TCFjby/XxSkAQxuWcL5Kv5ggOlYJtloyU+z1I8wGWs=";
                                AllowedIPs = ["10.100.100.4/32"];
                                PersistentKeepalive = 15;
                            }
                            {
                                # Backup Server
                                PublicKey = "rntfoR0iPjL90MhrwIFOVI0hSoZ8hHj8A512Q4+1hk4=";
                                AllowedIPs = ["10.100.100.5/32"];
                                PersistentKeepalive = 15;
                            }
                            {
                                # eNET Server
                                PublicKey = "VGMPRz95JuRtQMTYV2ANAF7AuDZU/igJgZB8ZZSAUXI=";
                                AllowedIPs = ["10.100.100.50/32"];
                                PersistentKeepalive = 15;
                            }
                            {
                                #Work Laptop
                                PublicKey = "1J9wofO7+gHgkNAOMl51K3WmMknle/2b0dGT8jVLdAo=";
                                AllowedIPs = ["10.100.100.51/32"];
                                PersistentKeepalive = 15;
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
                            matchConfig.Name = "wireguard0";
                            address = ["10.100.100.1/24"];
                            networkConfig = {
                                IPv4Forwarding = true;
                            };
                        };
                    };
                };
            };
        };
    };
}
