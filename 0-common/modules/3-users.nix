
# User Accounts ----------------------------------------------------------------------------------------------------------------------
{ config, lib, pkgs, modulesPath, ... }:
{ 
    sops.age.sshKeyPaths = [ "/persistent/etc/ssh/ssh_host_ed25519_key" ];
    sops.secrets.beatlink_hashed_password = {
        sopsFile = ../secrets.yaml;
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
            };
        };
    };
    security.sudo.wheelNeedsPassword = false;                           # Removes the need for entering passwords for sudo
}