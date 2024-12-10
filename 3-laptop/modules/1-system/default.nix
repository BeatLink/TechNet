# Laptop Configuration ###############################################################################################################
# TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    disabledModules = lib.mkIf config.installationEnvironmentEnable [ "./5-disko-data-drive.nix ];

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
        ./11-sound.nix
        ./12-printing.nix
        ./desktop-environment
    ];
}
