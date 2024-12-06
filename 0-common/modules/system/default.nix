# Common Configurations ###################################################################################################################
#
# This imports common configurations used by all devices in the TechNet
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    imports = [                                       
        ./0-locale.nix
        ./1-networking.nix
        ./2-software.nix
        ./3-ssh.nix
        ./4-avahi.nix
        ./5-fail2ban.nix
    ];
}
