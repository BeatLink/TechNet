# Common Configurations -------------------------------------------------------------------------------------------------------------------
{ config, lib, pkgs, modulesPath, ... }: 
{
    imports = [                                       
        ./modules/avahi.nix
        ./modules/fail2ban.nix
        ./modules/locale.nix
        ./modules/networking.nix
        ./modules/software.nix
        ./modules/ssh.nix
        ./modules/users.nix
    ];
}
