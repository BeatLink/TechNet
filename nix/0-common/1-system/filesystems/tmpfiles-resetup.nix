# Tmpfiles Reapplication #############################################################################################################################
#
# Keeps systemd-tmpfiles-resetup re-running on a switch so every tmpfiles rule in the tree is reapplied.
#

{ lib, ... }:
{
    systemd.services."systemd-tmpfiles-resetup" = {
        serviceConfig = {
            RemainAfterExit = lib.mkForce false; # Must stay false, or no tmpfiles rule is reapplied on a switch
        };
    };
}
