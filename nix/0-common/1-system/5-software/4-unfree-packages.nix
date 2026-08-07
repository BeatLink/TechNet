# Enables Unfree Packages ############################################################################################################################
# home-manager.useGlobalPkgs is set in nix/0-common/2-users, so this applies to user packages as well.
{
    nixpkgs.config.allowUnfree = true;
}
