{ config, lib, pkgs, ... }: 
{
    imports = [
        ./modules/1-boot.nix
        ./modules/2-filesystem.nix
    ];
}