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
        ./glances.nix
        ./home-assistant.nix
        ./homepage.nix
        ./mealie.nix
        ./motioneye.nix
        ./nextcloud.nix
        ./nginx-proxy-manager.nix
        ./ntfy.nix
        ./openbooks.nix
        ./pihole.nix
        ./syncthing.nix
        ./traccar.nix
        ./trilium.nix
        ./tubearchivist.nix
        ./uptime-kuma.nix
        ./watchtower.nix
    ];
}
