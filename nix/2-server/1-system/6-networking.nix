# Networking
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

{
    config,
    inputs,
    ...
}:
{
    # Prevents conflicts with pihole
    services.resolved = {
        enable = true;
        extraConfig = ''
            DNSStubListener=no
        '';
        fallbackDns = [
            "8.8.8.8"
            "1.1.1.1"
        ];
    };

    networking = {
        hostName = "Heimdall"; # Sets hostname
        hostId = "e5aa3553";
        nameservers = [
            "10.100.100.1"
        ];
        useNetworkd = true;
        firewall = {
            allowedUDPPorts = [ 51820 ]; # Allows Wireguard on Firewall
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
            trustedInterfaces = [ "wireguard0" ];

        };
    };
    sops.secrets.wireguard_private_key.sopsFile = "${inputs.self}/secrets/2-server.yaml";
    boot = {
        kernel.sysctl."net.ipv4.conf.all.forwarding" = true; # Enables routing between peers for wireguard
        initrd = {
            availableKernelModules = [
                "wireguard" # Needed for wireguard in initrd for remote LUKS unlocking
                "r8169" # Ethernet NIC driver
            ];
            secrets = {
                # Sops doesn't work in initrd so we use boot.initrd.secrets
                "${config.sops.secrets.wireguard_private_key.path}" =
                    config.sops.secrets.wireguard_private_key.path;
            };
            systemd = {
                services = {
                    fix_wireguard_key_perms = {
                        # The Wireguard privatekey must be owned by systemd-network to be used.
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
                            chown systemd-network:systemd-network ${config.sops.secrets.wireguard_private_key.path}
                        '';
                    };
                    "initrd-reboot" = {
                        description = "Reboot system after 10 minutes in initrd";
                        serviceConfig = {
                            Type = "oneshot";
                            ExecStart = "systemctl reboot";
                        };
                    };
                };
                # A failsafe to reboot the system if it is stuck in initrd after 10 minutes, hopefully it can fix any wireguard issues
                timers."initrd-reboot" = {
                    description = "Timer to reboot system after 10 minutes in initrd";
                    timerConfig = {
                        OnBootSec = "10min";
                        Unit = "initrd-reboot.service";
                    };
                    wantedBy = [ "timers.target" ];
                };
                # Sets up systemd-networkd in initrd using the same configuration from the booted system's network stack
                network = config.systemd.network;
            };
        };
    };
    systemd = {
        network = {
            enable = true;
            netdevs."01-wireguard" = {
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
                        # Laptop
                        PublicKey = "WlTdwgmdSvXTGjB+kaOkZEV9vyOk/fKELv3IkRdJOAE=";
                        AllowedIPs = [ "10.100.100.2/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Tablet
                        PublicKey = "rvOxr8WYaQRMHI8Ic0Td6mBOTwkI9U842AHkLrZDDkQ=";
                        AllowedIPs = [ "10.100.100.3/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # PinePhone
                        PublicKey = "3HLX2V7Z1+40bXbetzOt/K8BX7/65my77j0SlwIBDXo=";
                        AllowedIPs = [ "10.100.100.4/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Phone
                        PublicKey = "/TCFjby/XxSkAQxuWcL5Kv5ggOlYJtloyU+z1I8wGWs=";
                        AllowedIPs = [ "10.100.100.5/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Backup Server
                        PublicKey = "rntfoR0iPjL90MhrwIFOVI0hSoZ8hHj8A512Q4+1hk4=";
                        AllowedIPs = [ "10.100.100.6/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Bedroom Light
                        PublicKey = "9LaDCzP+4z/RtsvsnfpjZXit/jO/uXX5WkfVoTg6jk8=";
                        AllowedIPs = [ "10.100.100.10/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Kitchen Light
                        PublicKey = "VyrLnuEuy91wfmB/HKkNwWd4IgfNqAQJgRJMARsTsn4=";
                        AllowedIPs = [ "10.100.100.11/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Bathroom Light
                        PublicKey = "pI+KOi59lfvgQ8PmtynyK7xuLb6uO0/4wBCsNwUCIT0=";
                        AllowedIPs = [ "10.100.100.12/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Bedroom Desk Light
                        PublicKey = "91uAfJkcMhoSomuhbySJAIT7JaisG2un7DdYJRFDZ24=";
                        AllowedIPs = [ "10.100.100.13/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Outside Light
                        PublicKey = "YshQyFj6/TWY6BhJzJ1LDwEOWelnkVH34fqxbvvqsAE=";
                        AllowedIPs = [ "10.100.100.14/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Spare Bulb
                        PublicKey = "DpDA12iZrKftLcstYevFFzUkT+h77ZjUXhXHQ8CHG18=";
                        AllowedIPs = [ "10.100.100.15/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Fan IR
                        PublicKey = "Vu/SGB9mvrlVO2BsWrGVH8x548MBMZmQ+nTWnLtowns=";
                        AllowedIPs = [ "10.100.100.16/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Fan Socket
                        PublicKey = "R/KQHjZWDt+zDhCZMPiuVUQlbtaEKaL8LThzsOZbYSc=";
                        AllowedIPs = [ "10.100.100.17/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Ragnarok Socket
                        PublicKey = "oKg4d4atr/kVlXgfoKWqNPE/mGMo+uRhjJE4wPSUF2Q=";
                        AllowedIPs = [ "10.100.100.18/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Bathroom Light Sensor
                        PublicKey = "YUUKohrU/e0qzl9kM+HxB7A+fey7dnOq7e+sbjdoYDk=";
                        AllowedIPs = [ "10.100.100.19/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # Bedroom Light Sensor
                        PublicKey = "M2lsrnSfXEYydot27rsoNhHE3c6Mkq2rL6OfzGBjNwI=";
                        AllowedIPs = [ "10.100.100.20/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        # eNET Server
                        PublicKey = "VGMPRz95JuRtQMTYV2ANAF7AuDZU/igJgZB8ZZSAUXI=";
                        AllowedIPs = [ "10.100.100.52/32" ];
                        PersistentKeepalive = 25;
                    }
                    {
                        #Work Laptop
                        PublicKey = "1J9wofO7+gHgkNAOMl51K3WmMknle/2b0dGT8jVLdAo=";
                        AllowedIPs = [ "10.100.100.51/32" ];
                        PersistentKeepalive = 25;
                    }
                ];
            };
            networks = {
                "01-enp2s0f1" = {
                    matchConfig.Name = "enp2s0f1";
                    address = [ "192.168.0.2/24" ];
                    gateway = [ "192.168.0.1" ];
                    linkConfig.RequiredForOnline = "routable";
                };
                "01-wireguard" = {
                    matchConfig.Name = "wireguard0";
                    address = [ "10.100.100.1/24" ];
                    networkConfig = {
                        IPv4Forwarding = true;
                    };
                };
            };
        };
    };

}
