# Software ##########################################################################################################################
#
# Configures software settings
#
###########################################################################################################################################

{ config, lib, pkgs, ... }: 
{
    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";                           # Sets the Platform to ARM64
    system.stateVersion = "23.11";                                                  # Sets the system state version
}
