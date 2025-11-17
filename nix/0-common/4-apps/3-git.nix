# Git
#
# Version Control System
#

{ pkgs, ... }:
{
    home-manager.users.beatlink.programs.git = {
        enable = true;
        settings = {
            userEmail = "git@beatlink.simplelogin.com";
            userName = "BeatLink";
            core = {
                autocrlf = "input";
            };
        };
        package = pkgs.gitFull;
    };
}
