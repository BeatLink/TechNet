# Enable Flakes #################################################################################################################################
{ inputs, ... }:
{
    nix = {
        extraOptions = ''experimental-features = nix-command flakes''; # Enables Flakes
        registry.nixpkgs.flake = inputs.nixpkgs;
        nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ]; # Configures nix to use nixpkgs from flakes, fixes pesky errors in nix-shell
    };
    programs.command-not-found.enable = false;
    home-manager.users.beatlink = {
        programs.command-not-found.enable = false;
    };
}
