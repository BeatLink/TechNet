{ config, lib, pkgs, modulesPath, ... }: 
{
    networking = {
        domain = "TechNet";
        firewall = {
            enable = true;                                              # Enable the Firewall
                                            
        };
    };
}