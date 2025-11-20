# Git
#
# Version Control System
#

{ pkgs, ... }:
{
    home-manager.users.beatlink.programs.git = {
        enable = true;
        settings = {
            user = {
                email = "git@beatlink.simplelogin.com";
                name = "BeatLink";
            };
            core = {
                autocrlf = "input";
            };
        };
        package = pkgs.gitFull;
    };
}
