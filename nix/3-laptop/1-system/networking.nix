# Networking
#
# Wireguard is a simple, high performance VPN that allows each device in the TechNet to securely connect with each other and to
# connect to the internet via a secure relay through Heimdall. Every NetworkManager profile Odin uses is written out in full below.
#

{ config, lib, ... }:
{

    config = lib.mkMerge [

        # Sets Hostname ##############################################################################################################################
        {
            networking.hostName = "Odin";
        }

        # Uses Network Manager #######################################################################################################################
        {
            networking.networkmanager.enable = true;
        }

        # Custom Config for Odin #####################################################################################################################
        {
            networking.networkmanager.ensureProfiles.profiles = {
                "TechNet Wi-Fi" = {
                    ipv4 = {
                        method = "manual";
                        addresses = "192.168.0.3/24";
                    };
                };
                "TechNet WireGuard (Split Tunnel)" = {
                    ipv4 = {
                        addresses = "10.100.100.2/24";
                    };
                };
            };
        }
    ];

}
