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
        ./4-ssh.nix
        ./5-avahi.nix
        ./6-fail2ban.nix
        ./7-earlyoom.nix
        ./8-fastfetch.nix
    ];
}
