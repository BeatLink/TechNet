# Avahi ###################################################################################################################################
#
# Enables Avahi for LAN access via hostname.local
#
###########################################################################################################################################
    
{ config, lib, pkgs, modulesPath, ... }: 
{
    services.avahi = {
        enable = true;
        publish = {
            enable = true;                                              # Publishes the device so others can find it
            addresses = true;                                           # Publishes our address so others can find it
            workstation = true;                                         # Marks this device as a PC (Set to false for servers)
        };
    };
}