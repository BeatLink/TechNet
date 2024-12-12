{ config, lib, pkgs, ... }:
{
    imports = [
        ./gmusicbrowser.nix
        ./lmms.nix
        #./steam.nix
    ];
}
