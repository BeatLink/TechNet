# Flakes #############################################################################################################################################
#
# Enables flakes and pins nixpkgs, pulling in the token declared by github-token.nix.
#

{ config, inputs, ... }:
{
    nix = {
        extraOptions = ''
            experimental-features = nix-command flakes
            !include ${config.sops.secrets.github_access_token_conf.path}
        '';
        registry.nixpkgs.flake = inputs.nixpkgs;
        nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ]; # Configures nix to use nixpkgs from flakes, fixes pesky errors in nix-shell
    };
}
