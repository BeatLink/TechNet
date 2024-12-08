# Laptop Configuration ###############################################################################################################
# TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    imports = [                                   
        ./1-hardware-configuration.nix
        ./2-boot.nix
        ./3-disk-config.nix
        ./4-impermanence.nix
        #./5-data-drive.nix
        ./6-sops.nix
        ./7-software.nix
        ./8-networking.nix
        ./9-ssh.nix
        ./11-sound.nix
        ./12-printing.nix
        ./desktop-environment
    ];
}
