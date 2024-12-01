{ config, lib, pkgs, ... }:
{
    imports = [
        ./cinnamon.nix
        ./nvidia.nix
        ./vorta.nix
    ];
}
