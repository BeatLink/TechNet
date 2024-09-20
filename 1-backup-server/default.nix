{ config, lib, pkgs, ... }: 
{
    imports = [
        ./modules/0-hardware-configuration.nix
        ./modules/1-boot.nix
        ./modules/2-filesystem.nix
    ];
}