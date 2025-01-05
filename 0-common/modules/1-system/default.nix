# Common Configurations ###################################################################################################################
#
# This imports common configurations used by all devices in the TechNet
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    imports = [                                       
        ./1-software.nix
        ./2-networking.nix
        ./3-locale.nix
        ./4-certificates.nix
    ];
}
