# Software ###########################################################################################################################################

{
    system.stateVersion = "25.05";

    # Nothing this board builds itself reaches the rest of the fleet otherwise, and an aarch64 path is the expensive kind to rebuild.
    technet.atticPush.enable = true;
}
