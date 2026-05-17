# Enables Unfree Packages #######################################################################################################################
{
    nixpkgs.config.allowUnfree = true;

    home-manager.users.beatlink = {
        nixpkgs.config = {
            allowUnfree = true;
        };
    };
}
