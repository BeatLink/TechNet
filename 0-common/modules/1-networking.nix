# Networking ##############################################################################################################################
#
# Sets up default networking settings
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    networking = {
        domain = "TechNet";                                             # Sets the domain name
        firewall = {
            enable = true;                                              # Enable the Firewall
            logRefusedConnections = true;                               # Records any refused connections
            allowedUDPPorts = [ 51820 ];                                # Allow Wireguard in Firewall
        };
    };
}