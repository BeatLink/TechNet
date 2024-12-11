{ config, lib, pkgs, ... }:
{
    imports = [
        #./cinnamon.nix
        #./flatpak.nix
        ./dconf-editor.nix
        ./nvidia.nix
        #./vorta.nix
    ];
}
