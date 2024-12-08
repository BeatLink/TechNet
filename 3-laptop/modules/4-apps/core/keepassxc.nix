{ config, lib, pkgs, ... }:
{
    services.flatpak.packages = ["flathub:app/org.keepassxc.KeePassXC//stable"];
}