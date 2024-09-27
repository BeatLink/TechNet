# Home Server Configuration ###############################################################################################################
# TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    imports = [                                   
        ./0-hardware-configuration.nix
        ./1-disk-config.nix
        ./2-boot.nix
        ./3-networking.nix
        ./4-ssh.nix
        ./5-impermanence.nix
        ./6-data-drive.nix
        ./7-software.nix
        ./8-docker.nix
        ./9-borgmatic.nix
        ./services
    ];
}
