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
        #./7-networking.nix
        ./8-ssh.nix
        ./9-desktop-environment.nix
        ./10-sound.nix
        ./11-printing.nix
    ];
}
