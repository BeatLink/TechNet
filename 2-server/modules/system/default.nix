# Home Server Configuration ###############################################################################################################
# TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    imports = [                                   
        ./0-hardware-configuration.nix
        ./1-disk-config.nix
        ./2-boot.nix
        ./3-filesystem
        ./4-networking.nix
        ./5-ssh.nix
        ./6-software.nix
        ./7-docker.nix
        ./8-borgmatic.nix
        ./9-utilities.nix
    ];
}
