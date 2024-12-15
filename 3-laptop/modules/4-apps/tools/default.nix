{ config, lib, pkgs, ... }:
{
    imports = [
        ./decoder.nix
        ./virt-manager.nix
        #./deluge.nix
        ./qdirstat.nix
        #./redshift.nix
        #./valent.nix
    ];
}
