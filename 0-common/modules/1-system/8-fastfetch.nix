{ config, lib, pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ fastfetch ];                          # Install fastfetch
}
