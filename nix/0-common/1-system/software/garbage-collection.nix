# Garbage Collection #################################################################################################################################
#
# Collection of store paths older than a week. X-Nix runs it on every host each day (gc.collect_at in x-nix.nix), so the NixOS timer is off; its
# options are still the policy X-Nix collects with.
#

{ ... }:
{
    nix.gc = {
        automatic = false;
        options = "--delete-older-than 7d";
    };
}
