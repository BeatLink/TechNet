{ config, lib, pkgs, ... }:
{
    imports = [
        ./decoder.nix
        ./virt-manager.nix
        #./deluge.nix
        #./fastfetch.nix
        #./redshift.nix
        ./valent.nix
    ];
}
