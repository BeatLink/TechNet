{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink = { config, pkgs, ... }: {
        programs.plasma.workspace = {               
            clickItemTo = "select";
            enableMiddleClickPaste = true;
            tooltipDelay = 5;
            theme = "breeze-light";
            colorScheme = "BreezeLight";
            cursor = {
                theme = "Breeze_Light";
                size = 24;
            };     
            lookAndFeel = "org.kde.breeze.desktop";
            iconTheme = "breeze";
            soundTheme = "ocean";
        };
    };
}