{ config, lib, pkgs, ... }:
{
    environment.systemPackages = with pkgs; [ dupeguru ];
}
