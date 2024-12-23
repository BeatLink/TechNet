{ config, lib, pkgs, ... }:
{
    imports = [
        ./firefox.nix
        ./keepassxc.nix
        ./moneymanager.nix
        ./trilium.nix
        
    ];
}



