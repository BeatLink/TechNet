# Networking #########################################################################################################################################
#
# The board's identity and its wired address by DHCP. It is not a WireGuard peer: it has no key and no address in the tunnel.
#

{
    config = {
        networking = {
            hostName = "Rock64";
            useNetworkd = true;
        };

        systemd.network = {
            enable = true;
            networks."01-end0" = {
                matchConfig.Name = "end0";
                networkConfig.DHCP = "ipv4";
                linkConfig.RequiredForOnline = "routable";
            };
        };
    };
}
