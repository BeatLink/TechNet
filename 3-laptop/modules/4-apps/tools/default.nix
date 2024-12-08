{ config, lib, pkgs, ... }:
{
    imports = [
        ./decoder.nix
        ./vscodium.nix
        ./virt-manager.nix
        #./deluge.nix
        #./fastfetch.nix
        #./redshift.nix
        #./valent.nix
    ];
}
