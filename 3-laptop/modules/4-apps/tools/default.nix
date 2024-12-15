{ config, lib, pkgs, ... }:
{
    imports = [
        ./decoder.nix
        #./deluge.nix
        ./partition-manager.nix
        ./qdirstat.nix
        ./virt-manager.nix
    ];
}
