# Garbage Collection #################################################################################################################################
#
# Weekly collection of store paths older than a week.
#

{ ... }:
{
    nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
    };
}
