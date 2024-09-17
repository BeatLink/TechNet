# Home Server Configuration ###############################################################################################################
# TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    imports = [              

        # Core Modules                         
        ./modules/0-hardware-configuration.nix
        ./modules/1-disk-config.nix
        ./modules/2-boot.nix
        ./modules/3-networking.nix
        ./modules/4-ssh.nix
        ./modules/5-impermanence.nix
        ./modules/6-data-drive.nix
        ./modules/7-software.nix
        ./modules/8-docker.nix
        ./modules/9-borgmatic.nix

        # Docker Services
        ./services/blockurl.nix
        ./services/calibre.nix
        ./services/dashy.nix
        ./services/deluge.nix
    ];
}
