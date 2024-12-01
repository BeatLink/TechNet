{ config, lib, pkgs, ... }:
{
    imports = [
        ./deluge.nix
        ./fastfetch.nix
        ./valent.nix
    ];
}
