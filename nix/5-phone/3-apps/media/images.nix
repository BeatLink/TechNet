# XViewer ############################################################################################################################################
{ pkgs, ... }:
{
    home-manager.users.beatlink.home = {
        packages = [ pkgs.xviewer ];
        persistence."/Storage/Apps/Media/XViewer".directories = [ ".config/xviewer" ];
    };
}
