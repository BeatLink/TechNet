# Software ###########################################################################################################################################

{
    system.stateVersion = "25.05";

    # Nothing this board builds itself reaches the rest of the fleet otherwise, and an aarch64 path is the expensive kind to rebuild.
    technet.atticPush.enable = true;

    # Three of the four cores, and one job at a time: a build large enough to use them all goes IO-bound against 2GB of RAM long before it runs out
    # of CPU.
    nix.settings = {
        cores = 3;
        max-jobs = 1;
    };
}
