{ config, lib, pkgs, ... }:
{
    imports = [
        ./discord.nix
        ./element.nix
        ./thunderbird.nix
        ./whatsapp.nix
    ];
}
