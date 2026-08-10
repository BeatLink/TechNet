# GitHub Access Token ################################################################################################################################
#
# The token flake fetching authenticates with, read into nix.conf by flakes.nix.
#

{ config, ... }:
{
    sops.secrets.github_access_token_conf = {
        sopsFile = "${config.technet.secrets.commonPath}/github.yaml";
        owner = "beatlink"; # Owned, not root-only, because flake fetching runs as the user and `!include` swallows the permission error
    };
}
