# Users ###################################################################################################################################
#
# Configures the user accounts for devices in the TechNet
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }: 
{
    imports = [                                       
        ./beatlink
    ];
    users = {
        mutableUsers = false;                                           # Have users be managed by NixOS Config File
        users.root.hashedPassword = "!";                                # Disables Root Account
    };
    security.sudo.wheelNeedsPassword = false;                           # Removes the need for entering passwords for sudo
}
