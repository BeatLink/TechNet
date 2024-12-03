
{ config, pkgs, ... }: 
{
    home.packages = with pkgs; [ gnome-decoder ];
    # services.flatpak.packages = ["flathub:app/com.belmoussaoui.Decoder//stable"];
}