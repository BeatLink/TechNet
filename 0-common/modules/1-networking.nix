{ config, lib, pkgs, modulesPath, ... }: 
{
    networking = {
        domain = "TechNet";                                             # Sets the domain name
        firewall = {
            enable = true;                                              # Enable the Firewall
            logRefusedConnections = true;
            allowedUDPPorts = [
                51820                                                   # Wireguard
            ];
        };
    };
}