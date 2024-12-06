# Laptop Configuration ###############################################################################################################
# TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    imports = [                                   
        ./1-hardware-configuration-vm.nix
        #./1-disk-config.nix
        ./2-boot.nix
        ./3-disk-config.nix
        ./4-impermanence.nix
        #./5-data-drive.nix
        ./6-software.nix
        ./7-networking.nix
        ./8-desktop-environment.nix
        ./9-sound.nix
        ./10-printing.nix
    ];
}
