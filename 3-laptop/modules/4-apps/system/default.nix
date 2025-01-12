{ config, lib, pkgs, ... }:
{
    imports = [
        ./bash.nix
        ./dconf-editor.nix
        ./fonts.nix
        ./variety.nix
        ./vorta.nix
        ./nemo
        ./blueman
    ];
}
