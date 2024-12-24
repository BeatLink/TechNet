{ config, lib, pkgs, ... }:
{
    imports = [
        ./bash.nix
        ./dconf-editor.nix
        ./fonts.nix
        ./dolphin.nix
        ./nemo
        ./vorta.nix
    ];
}
