# Software ###########################################################################################################################################
{ pkgs, ... }:
{
    system.stateVersion = "25.05";

    environment.systemPackages = [
        pkgs.wl-clipboard # Command line clipboard access for the session, which windowless programs like Waydroid's bridge shell out to
    ];
}
