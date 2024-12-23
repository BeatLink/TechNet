{ config, lib, pkgs, ... }:
{
    imports = [
        ./firefox.nix
        ./keepassxc.nix
        ./moneymanager.nix
        
    ];
    environment.systemPackages = [(pkgs.callPackage ./trilium { })];
}



