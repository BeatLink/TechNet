{ config, lib, pkgs, ... }:
{
    imports = [
        ./thunderbird.nix
        ./element.nix
    ];
}
