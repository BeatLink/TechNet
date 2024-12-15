{ config, lib, pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ filelight ];                          # Install filelight
}
