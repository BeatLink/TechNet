# EarlyOom ################################################################################################################################
#
# Prevents Out Of Memory Conditions by killing the largest process if memory drops below 10% free
#
###########################################################################################################################################
{ config, lib, pkgs, modulesPath, ... }: 
{
    environment.systemPackages = with pkgs; [ earlyoom ];                     # Installs earlyoom
}