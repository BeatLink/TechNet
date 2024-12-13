{ config, lib, pkgs, ... }:
{
    imports = [
        ./calibre.nix
        ./freetube.nix
        ./gmusicbrowser.nix
        ./lmms.nix
        #./steam.nix
        ./stremio.nix
    ];
}
