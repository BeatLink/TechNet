# EarlyOom ################################################################################################################################
#
# Prevents Out Of Memory Conditions by killing the largest process if memory drops below 10% free
#
###########################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: 
{
    services.earlyoom = {
        enable = true;
        enableNotifications = true;
        freeMemThreshold = 2;
    };
}