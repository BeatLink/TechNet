# Networking ##############################################################################################################################
#
# Sets up default networking settings
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    networking = {
        firewall = {
            enable = true;                                              # Enable the Firewall
            logRefusedConnections = true;                               # Records any refused connections
        };
    };
}