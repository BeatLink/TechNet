
{ config, pkgs, ... }: 
{
    services.flatpak = {
        enableModule = true;
        flatpak-dir = "/media/beatlink/Storage/Apps/Flatpak";
        remotes = {
            "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
            "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
        };
    };
}