{ config, lib, pkgs, ... }:
{
    imports = [
        ./audacious.nix
        ./calibre.nix
        ./freetube.nix
        ./gmusicbrowser.nix
        ./lmms.nix
        ./newsflash.nix
        ./steam.nix
        ./stremio.nix
        ./vlc.nix
    ];
}
