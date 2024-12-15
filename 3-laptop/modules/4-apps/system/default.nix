{ config, lib, pkgs, ... }:
{
    imports = [
        #./cinnamon.nix
        #./flatpak.nix
        ./dconf-editor.nix
        ./fonts.nix
        ./nvidia.nix
        ./nemo
        ./vorta.nix
    ];
}
