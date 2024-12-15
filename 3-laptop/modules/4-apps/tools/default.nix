{ config, lib, pkgs, ... }:
{
    imports = [
        ./decoder.nix
        #./deluge.nix
        ./libreoffice.nix
        ./partition-manager.nix
        ./qdirstat.nix
        ./virt-manager.nix
    ];
}
