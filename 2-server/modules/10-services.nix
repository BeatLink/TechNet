# Home Server Configuration ###############################################################################################################
# TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    imports = [              
        # Docker Services
        ./services/blockurl.nix
        ./services/calibre.nix
        ./services/dashy.nix
        ./services/deluge.nix
        ./services/freshrss.nix
        ./services/glances.nix
        ./services/motioneye.nix
        ./services/esphome.nix
    ];
}
