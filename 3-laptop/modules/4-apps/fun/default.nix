{ config, lib, pkgs, ... }:
{
    imports = [
        ./audacious.nix
        ./calibre.nix
        ./freetube.nix
        ./gmusicbrowser.nix
        ./lmms.nix
        ./lutris.nix
        ./newsflash.nix
        ./steam.nix
        ./stremio.nix
        ./vlc.nix
    ];
}
