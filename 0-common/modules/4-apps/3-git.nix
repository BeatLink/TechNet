# Git
#
# Version Control System                                                
#

{ pkgs, ... }:
{
    home-manager.users.beatlink.programs.git = {
        enable = true;
        userEmail = "git@beatlink.simplelogin.com";
        userName = "BeatLink";
        package = pkgs.gitFull;
        extraConfig = {
            core = {
                autocrlf = "input";
            };
        };
    };
}