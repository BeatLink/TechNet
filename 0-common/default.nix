# Common Configurations -------------------------------------------------------------------------------------------------------------------
{ config, lib, pkgs, modulesPath, ... }: 
{
    imports = [                                       
        ./modules/0-locale.nix
        ./modules/1-networking.nix
        ./modules/2-software.nix
        ./modules/3-users.nix
        ./modules/4-ssh.nix
        ./modules/5-avahi.nix
        ./modules/6-fail2ban.nix
    ];
}
