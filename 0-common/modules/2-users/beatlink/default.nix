{ config, lib, pkgs, modulesPath, ... }: 
{
    imports = [                                       
        ./home-manager.nix
        ./user-account.nix
    ];
}
