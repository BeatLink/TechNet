{ config, lib, pkgs, ... }:
{
    imports = [
        ./bash.nix
        ./dconf-editor.nix
        ./fonts.nix
        ./nemo
        ./vorta.nix
    ];
}
