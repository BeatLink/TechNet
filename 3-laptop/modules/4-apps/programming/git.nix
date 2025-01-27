{ config, lib, pkgs, ... }:
{
    home-manager.users.beatlink.programs.git = {
        enable = true;
        userEmail = "github@beatlink.simplelogin.com";
        userName = "BeatLink";
        #package = pkgs.gitFull;
        #extraConfig = {
        #    credential.helper = "${
        #        pkgs.git.override { withLibsecret = true; }
        #    }/bin/git-credential-libsecret";
        #};
    };
}
