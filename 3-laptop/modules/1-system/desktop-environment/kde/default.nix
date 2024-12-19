{ config, lib, pkgs, ... }:
{
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.desktopManager.plasma6.enable = true;

    programs.kdeconnect.enable = true;

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
        elisa
        discover
        kate
    ];

    home-manager.users.beatlink = { config, pkgs, ... }: {

        programs.plasma.enable = true;

        /*input.touchpads = [
            
        ];*/

        imports = [
            ./hot-corners.nix
            ./panels.nix
            ./power.nix
            ./screenlock.nix
            ./workspace.nix
        ];
    };
}