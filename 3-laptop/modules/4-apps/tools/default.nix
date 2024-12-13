{ config, lib, pkgs, ... }:
{
    imports = [
        ./decoder.nix
        ./virt-manager.nix
        #./deluge.nix
        #./redshift.nix
        #./valent.nix
    ];
}
