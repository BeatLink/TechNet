{ config, lib, pkgs, modulesPath, ... }: 
{
    networking = {
        domain = "TN";
        firewall = {
            enable = true;                                              # Enable the Firewall
            logRefusedConnections = true;
        };
    };
}