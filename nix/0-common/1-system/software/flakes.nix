# Flakes #############################################################################################################################################
#
# Enables flakes, pins nixpkgs to the flake's own input, and keeps Nix's profile links under ~/.local/state.
#

{ inputs, ... }:
{
    nix = {
        settings.use-xdg-base-directories = true;
        extraOptions = ''
            experimental-features = nix-command flakes
        '';
        registry.nixpkgs.flake = inputs.nixpkgs;
        nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ]; # Configures nix to use nixpkgs from flakes, fixes pesky errors in nix-shell
    };
}
