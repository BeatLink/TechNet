{ config, lib, pkgs, ... }:
{
    imports = [
        ./cinnamon.nix
        ./flatpak.nix
        ./nvidia.nix
        ./vorta.nix
    ];
}
