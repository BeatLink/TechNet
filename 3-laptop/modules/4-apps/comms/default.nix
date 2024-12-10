{ config, lib, pkgs, ... }:
{
    imports = [
        ./element.nix
        ./thunderbird.nix
        ./whatsapp.nix
    ];
}
