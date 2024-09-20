{ config, lib, pkgs, ... }: 
{
    imports = [
        ./modules/0-hardware-configuration.nix
        ./modules/1-boot.nix
        ./modules/2-networking.nix
        ./modules/3-ssh.nix
        ./modules/4-software.nix
        ./modules/5-backup-drive.nix
        ./modules/6-borg.nix
    ];
}