{ config, lib, pkgs, ... }:
{
    imports = [
        #./clock.nix
        ./cheese.nix
        ./calculator.nix
        ./czkawka.nix
        ./decoder.nix
        ./deluge.nix
        ./dupeguru.nix
        ./libreoffice.nix
        ./virt-manager.nix
    ];
}
