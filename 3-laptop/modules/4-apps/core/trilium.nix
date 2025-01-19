{ config, lib, pkgs, ... }:
{
   
    environment.systemPackages = [ pkgs.trilium-next-desktop ];
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