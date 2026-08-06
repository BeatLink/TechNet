# WebLaunch ############################
{ pkgs, ... }:
{
    # Apps ---------------------------------------
    programs.weblaunch.apps = {
        trilium = {
            name = "Trilium";
            url = "https://trilium.heimdall.technet";
            icon = "${pkgs.trilium-desktop}/share/icons/hicolor/512x512/apps/trilium.png";
            profile = "/home/beatlink/.local/share/weblaunch/Trilium";
            decorations = false;
        };

        syncthing = {
            name = "Syncthing";
            url = "http://localhost:8384";
            icon = "${pkgs.syncthing}/share/icons/hicolor/scalable/apps/syncthing.svg";
            profile = "/home/beatlink/.local/share/weblaunch/Syncthing";
            decorations = false;
        };

        home-assistant.decorations = false;
    };

    # Persistence --------------------------------
    home-manager.users.beatlink.home.persistence."/Storage/Apps/Core/WebLaunch".directories = [
        ".local/share/weblaunch/Trilium"
        ".local/share/weblaunch/Syncthing"
    ];
}
