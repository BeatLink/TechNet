{ config, lib, pkgs, modulesPath, ... }: 
{
    programs.partition-manager.enable = true;
    environment.systemPackages = with pkgs; [ gparted ];
}