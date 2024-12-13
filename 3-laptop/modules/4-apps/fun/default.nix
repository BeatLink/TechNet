{ config, lib, pkgs, ... }:
{
    imports = [
        ./freetube.nix
        ./gmusicbrowser.nix
        ./lmms.nix
        #./steam.nix
        ./stremio.nix
    ];
}
