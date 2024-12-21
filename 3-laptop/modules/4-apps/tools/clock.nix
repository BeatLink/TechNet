
{ config, pkgs, ... }: 
{
    environment.systemPackages = with pkgs; [ kclock ];

}