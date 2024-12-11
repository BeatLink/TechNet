{ config, lib, pkgs, ... }:
{
    imports = [     
        ./git.nix
        ./vscodium.nix
    ];
}
