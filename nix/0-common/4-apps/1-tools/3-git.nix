# Git ################################################################################################################################################
#
# Version control system for beatlink, using the full build for its extra commands.
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
        signing.format = null;
        package = pkgs.gitFull;
    };
}
