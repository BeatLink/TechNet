{ config, lib, pkgs, ... }:
{
   
    environment.systemPackages = [(pkgs.callPackage ./trilium { })];
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