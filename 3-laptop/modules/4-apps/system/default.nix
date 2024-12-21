{ config, lib, pkgs, ... }:
{
    imports = [
        ./dconf-editor.nix
        ./fonts.nix
        ./nemo
        ./vorta.nix
    ];
}
