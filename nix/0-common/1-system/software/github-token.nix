# GitHub Access Token ################################################################################################################################
#
# The token flake fetching authenticates with, and the nix.conf include that reads it.
#

{ config, lib, ... }:
{
    sops.secrets.github_access_token_conf = {
        sopsFile = "${config.technet.secrets.commonPath}/github.yaml";
        owner = "beatlink"; # Owned, not root-only, because flake fetching runs as the user and `!include` swallows the permission error
        group = "vigil-monitor"; # Vigil's Update Flake pushes the updated lock back to GitHub with it
        mode = "0440";
    };

    # extraOptions is types.lines, so this joins onto whatever flakes.nix sets; mkAfter pins it last rather than trusting module order
    nix.extraOptions = lib.mkAfter ''
        !include ${config.sops.secrets.github_access_token_conf.path}
    '';
}
