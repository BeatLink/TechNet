
{ config, lib, pkgs, modulesPath, ... }: 
{
    imports = [
        ./0-sd-image.nix
        ./1-boot.nix
        ./3-software.nix
        ./4-networking.nix
        ./5-backup-drive.nix
        ./6-borg.nix
    ];
}