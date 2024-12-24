
{ config, lib, pkgs, ... }:

{
    environment.systemPackages = with pkgs; [ dolphin ];
    home-manager.users.beatlink = { config, pkgs, ... }: {
        programs.plasma.configFile = {
            "dolphinrc" = {
                "General" = {
                    "FilterBar" = true;
                    "OpenExternallyCalledFolderInNewTab" = true;
                    "ShowFullPath" = true;
                    "ShowFullPathInTitlebar" = true;
                    "ViewPropsTimestamp" = "2024,12,24,7,45,57.603";
                };
                "InformationPanel"."previewsAutoPlay" = true;
                "KFileDialog Settings" = {
                    "Places Icons Auto-resize" = false;
                    "Places Icons Static Size" = 22;
                };
                "PreviewSettings"."Plugins" = "appimagethumbnail,audiothumbnail,blenderthumbnail,comicbookthumbnail,cursorthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,windowsexethumbnail,windowsimagethumbnail,mobithumbnail,opendocumentthumbnail,gsthumbnail,rawthumbnail,svgthumbnail,textthumbnail,ffmpegthumbs";
            };
        };
        home = {
            persistence."/Storage/Apps/System/Dolphin" = {
                directories = [
                    ".local/share/dolphin"
                ];
                files = [
                    ".config/dolphinrc"
                ];
                allowOther = true;
            };
        };
    };
}