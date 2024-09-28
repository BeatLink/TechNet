
{ config, lib, pkgs, modulesPath, ... }: 
{
    imports = [
        ./0-sd-image.nix
        ./1-boot.nix
        ./3-software.nix
        ./4-networking.nix
        ./5-ssh.nix
        ./6-backup-drive.nix
        ./7-borg.nix
    ];
}