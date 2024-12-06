# Home Server Configuration ###############################################################################################################
# TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    imports = [                                   
        ./1-hardware-configuration.nix
        ./2-boot.nix
        ./3-disk-config.nix
        ./4-impermanence.nix
        ./5-data-drive.nix
        ./6-software.nix
        ./7-networking.nix
        ./8-ssh.nix
        ./9-docker.nix
        ./10-borgmatic.nix
        ./11-utilities.nix
    ];
}
