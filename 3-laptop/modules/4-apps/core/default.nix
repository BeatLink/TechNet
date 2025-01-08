{ config, lib, pkgs, ... }:
{
    imports = [
        ./firefox.nix
        ./keepassxc.nix
        ./trilium.nix
        
    ];
}



