{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink.programs.git = {
        enable = true;
        userEmail = "github@beatlink.simplelogin.com";
        userName = "BeatLink";
        package = pkgs.gitFull;
    };
}
