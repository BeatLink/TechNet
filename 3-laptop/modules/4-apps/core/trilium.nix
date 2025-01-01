{ config, lib, pkgs, pkgs-unstable-small, ... }:
{
   
    environment.systemPackages = [(pkgs.callPackage ./trilium { pkgs-unstable-small = pkgs-unstable-small; })];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        home = {
            persistence."/Storage/Apps/Core/Trilium" = {
                directories = [
                    ".local/share/trilium-data"
                    ".config/TriliumNext Notes"
                ];
                allowOther = true;
            };
        };
    };
}