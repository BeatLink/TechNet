# Git ################################################################################################################################################
#
# Version control system for beatlink, using the full build for its extra commands.
#

{ lib, pkgs, ... }:
{
    home-manager.users.beatlink.programs.git = {
        enable = true;
        settings = {
            user = {
                email = "47278150+BeatLink@users.noreply.github.com";
                name = "BeatLink";
            };
            core = {
                autocrlf = "input";
            };
            gpg.ssh.allowedSignersFile = "${../../3-services/allowed-signers}";
        };
        signing.format = lib.mkDefault null;
        package = pkgs.gitFull;
    };
}
