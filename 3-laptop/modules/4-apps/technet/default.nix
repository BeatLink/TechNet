{ config, lib, pkgs, ... }:
{
    imports = [     
        ./home-assistant
        ./nextcloud.nix
        ./syncthing.nix
    ];
}
