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
        ./3-users.nix
        ./4-ssh.nix
        ./5-avahi.nix
        ./6-fail2ban.nix
    ];
}
