{ config, lib, pkgs, ... }:
{
    services.flatpak.packages = ["flathub:app/com.vscodium.codium//stable"];
}