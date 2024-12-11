{ config, lib, pkgs, ... }:
{
    environment.systemPackages = [
        pkgs.dconf-editor
    ];
}