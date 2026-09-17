# Software ###########################################################################################################################################
{ pkgs, ... }:
{
    system.stateVersion = "25.05";

    # Nothing this phone builds itself reaches the rest of the fleet otherwise, and an aarch64 path is the expensive kind to rebuild.
    technet.atticPush.enable = true;

    environment.systemPackages = [
        pkgs.wl-clipboard # Command line clipboard access for the session, which windowless programs shell out to
    ];
}
