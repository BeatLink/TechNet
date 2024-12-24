{ config, lib, pkgs, ... }:
{
    imports = [
        ./dconf-editor.nix
        ./fonts.nix
        ./dolphin.nix
        ./nemo
        ./vorta.nix
    ];
}
