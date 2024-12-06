
{ config, lib, pkgs, modulesPath, ... }: 
{
    imports = [
        ./1-sd-image.nix
        ./2-boot.nix
        ./3-software.nix
        ./4-networking.nix
        ./5-backup-drive.nix
        ./6-borg.nix
    ];
}