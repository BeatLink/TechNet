{ config, lib, pkgs, ... }:
{
    imports = [
        ./bash.nix
        ./dconf-editor.nix
        ./fonts.nix
        ./vorta.nix
    ];
}
