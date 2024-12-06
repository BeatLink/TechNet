
{ config, lib, pkgs, modulesPath, ... }: 
{
    imports = [
        ./0-sd-image.nix
        ./1-boot.nix
        ./2-networking.nix
        ./3-software.nix
        ./4-backup-drive.nix
        ./5-borg.nix
    ];
}