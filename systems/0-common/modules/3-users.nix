
# User Accounts ###########################################################################################################################
# 
# Configures my user account
#
###########################################################################################################################################

{ config, lib, pkgs, modulesPath, ... }:
{ 
    sops.secrets.beatlink_hashed_password = {
        sopsFile = ../secrets/secrets.yaml;
        neededForUsers = true;
    };
    users = {
        mutableUsers = false;                                           # Have users be managed by NixOS Config File
        groups."beatlink" = {};                                         # Creates group for my account
        users = {
            root.hashedPassword = "!";                                  # Disables Root Account
            "beatlink" = {                                              # Creates my account
                isNormalUser = true;                                    # Real (non service) user
                description = "BeatLink";                               # Sets the name of the user
                hashedPasswordFile = config.sops.secrets.beatlink_hashed_password.path;    # Sets my password using sops
                group = "beatlink";                                     # Adds me to my group
                extraGroups = [ "networkmanager" "wheel"];              # Allows management of the network and using sudo
                openssh.authorizedKeys.keys = [                         # Sets the SSH key for the user
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4GfJHxZu55mhQPpL1MqLCrS4ws/1ZUodC/QicApyGF beatlink@technet"
                ]; 
            };
        };
    };
    security.sudo.wheelNeedsPassword = false;                           # Removes the need for entering passwords for sudo
}