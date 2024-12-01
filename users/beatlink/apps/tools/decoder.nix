
{ config, pkgs, ... }: 
{
    services.flatpak.packages = ["flathub:app/com.belmoussaoui.Decoder//stable"];
}