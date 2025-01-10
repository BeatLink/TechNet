{ config, lib, pkgs, ... }:
{
    imports = [
        #./clock.nix
        ./czkawka.nix
        ./decoder.nix
        #./deluge.nix
        ./dupeguru.nix
        ./libreoffice.nix
        ./partition-manager.nix
        ./qdirstat.nix
        ./virt-manager.nix
    ];
}
