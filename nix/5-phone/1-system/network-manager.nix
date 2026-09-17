# Networking
#
# Wireguard is a simple, high performance VPN that allows each device in the TechNet to securely connect with each other and to
# connect to the internet via a secure relay through Heimdall. Every NetworkManager profile Thor uses is written out in full below,
# including the keys NetworkManager itself wrote on-device (permissions, dns-search, mode, mac-address-blacklist, auth-alg), which
# are kept so the generated keyfiles stay byte-identical to what the phone is already running.
#

{ lib, ... }:
{

    config = lib.mkMerge [
        # Sets Hostname ##############################################################################################################################
        {
            networking.hostName = "Thor";
        }

        # Uses Network Manager #######################################################################################################################
        {
            networking.networkmanager.enable = true;
        }

        # Custom Config for Thor #####################################################################################################################
        {
            networking.networkmanager.ensureProfiles.profiles = {
                "TechNet Wi-Fi" = {
                    wifi.band = "bg"; # Thor's rtl8723cs is 2.4GHz only, so the shared 5GHz default matches no AP it can see.
                    wifi.hidden = lib.mkForce false;
                };
                "TechNet WireGuard (Split Tunnel)" = {
                    ipv4.addresses = "10.100.100.4/24";
                };
                "TechNet WireGuard (Full Tunnel)" = {
                    ipv4.addresses = "10.100.100.4/24";
                    connection.autoconnect = "false"; # Both profiles claim wireguard0, so only the split tunnel comes up on its own.
                };
            };
        }
    ];

}
