# Git Commit Signing #################################################################################################################################
#
# Signs every commit made on the laptop with its own SSH key, kept in sops, so Odin's X-Nix pull mode accepts the branch heads it pushes.
#

{ config, ... }:
{
    sops.secrets.git_signing_key = {
        sopsFile = "${config.technet.secrets.path}/git-signing.yaml";
        owner = "beatlink";
    };

    home-manager.users.beatlink.programs.git.signing = {
        format = "ssh";
        key = config.sops.secrets.git_signing_key.path;
        signByDefault = true;
    };
}
