# Laptop Configuration ###############################################################################################################
# TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    imports = [                                   
        ./1-hardware-configuration.nix
        ./2-boot.nix
        ./3-disko-root-drive.nix
        ./4-impermanence.nix
        ./5-disko-data-drive.nix
        ./6-sops.nix
        ./7-software.nix
        ./8-networking.nix
        ./9-ssh.nix
        ./10-display.nix
        ./11-sound.nix
        ./12-printing.nix
        ./13-fuse.nix
        ./14-home-folders.nix
        ./desktop-environment
        ./bluetooth.nix

    ];
}
