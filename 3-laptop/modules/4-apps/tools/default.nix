{ config, lib, pkgs, ... }:
{
    imports = [
        ./decoder.nix
        ./virt-manager.nix
        #./deluge.nix
        ./filelight.nix
        #./redshift.nix
        #./valent.nix
    ];
}
