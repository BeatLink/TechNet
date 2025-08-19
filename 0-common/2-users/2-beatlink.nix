# BeatLink
# 
# Configures my user account
#

{ config, impermanence, ... }:
{
    # Setup Linux User Account
    sops.secrets.beatlink_hashed_password = {
        sopsFile = ../../secrets.yaml;
        neededForUsers = true;
    };
    users = {
        groups."beatlink" = {};                                                 # Creates group for my account
        users = {
            "beatlink" = {                                                      # Creates my account
                isNormalUser = true;                                            # Real (non service) user
                description = "BeatLink";                                       # Sets the name of the user
                hashedPasswordFile = config.sops.secrets.beatlink_hashed_password.path;    # Sets my password using sops
                group = "beatlink";                                             # Adds me to my group
                extraGroups = [ "networkmanager" "wheel" "libvirtd" "borg" "audio" "pipewire"];    # Allows management of the network, using sudo, virt-manager, and accessing borg repos
                openssh.authorizedKeys.keys = [                                 # Sets the SSH key for the user
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4GfJHxZu55mhQPpL1MqLCrS4ws/1ZUodC/QicApyGF beatlink@technet"
                ]; 
            };
        };
    };

    # Allow Nix Package Management
    nix.settings.trusted-users = ["beatlink"];

    # Setup Home Manager
    home-manager.users.beatlink = {
        imports = [ impermanence.homeManagerModules.impermanence ];
        home = {
            username = "beatlink";
            homeDirectory = "/home/beatlink";
            stateVersion = "24.11";                                             # Dont change unless reinstalled.
            sessionVariables = {
                EDITOR = "nano";
            };
        };
        systemd.user.startServices = "sd-switch";
    };
}
