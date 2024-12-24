{ config, lib, pkgs, ... }:
{
    imports = [     
        ./kde-connect.nix
        ./home-assistant
        ./nextcloud.nix
        ./syncthing.nix
    ];
}
