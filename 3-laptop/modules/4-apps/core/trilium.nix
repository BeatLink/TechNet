{ config, lib, pkgs, ... }:
{
    nixpkgs.config.permittedInsecurePackages = [
        "electron-31.7.7"
    ];
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