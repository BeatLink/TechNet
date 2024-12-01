{ config, lib, pkgs, ... }:
{
    imports = [
        ./decoder.nix
        ./deluge.nix
        ./fastfetch.nix
        ./redshift.nix
        ./valent.nix
    ];
}
