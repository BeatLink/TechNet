# Home Server Configuration ###############################################################################################################
# TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    imports = [              
        ./blockurl.nix
        ./calibre-web.nix
        ./dashy.nix
        ./deluge.nix
        ./esphome.nix
        ./freshrss.nix
        ./glances.nix
        ./home-assistant.nix
        ./motioneye.nix
        ./nextcloud.nix
    ];
}
