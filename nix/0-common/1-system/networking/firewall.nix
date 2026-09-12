# Enable the Firewall
{
    # Configures Firewall ############################################################################################################################
    networking.firewall = {
        enable = true;
        allowedUDPPorts = [ 51820 ];
        trustedInterfaces = [ "wireguard0" ];
        checkReversePath = false;
    };
}
