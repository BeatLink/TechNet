# Home Server Configuration ###############################################################################################################
# TODO: Add Notes
###########################################################################################################################################

{ config, lib, pkgs, ... }:
{
    imports = [              
        ./blockurl.nix
        ./calibre-web.nix
        ./deluge.nix
        ./esphome.nix
        ./freshrss.nix
        ./gallery-dl.nix
        ./glances.nix
        ./home-assistant.nix
        ./homepage.nix
        ./mealie.nix
        ./motioneye.nix
        ./nextcloud.nix
        ./nginx-proxy-manager.nix
        ./openbooks.nix
        ./pihole.nix
        ./syncthing.nix
        ./traccar.nix
        ./trilium.nix
        ./uptime-kuma.nix
        ./watchtower.nix
    ];
}
