# Flakes #############################################################################################################################################
#
# Enables flakes and pins nixpkgs to the flake's own input.
#

{ inputs, ... }:
{
    nix = {
        extraOptions = ''
            experimental-features = nix-command flakes
        '';
        registry.nixpkgs.flake = inputs.nixpkgs;
        nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ]; # Configures nix to use nixpkgs from flakes, fixes pesky errors in nix-shell
    };
}
