# Swap ###############################################################################################################################################
#
# Ordering for the swap zvol declared in disko.nix.
#

{ config, ... }:
let
    swapZvol = "dev-zvol-root-pool-${config.networking.hostName}-swap";
in
{
    systemd.services."mkswap-${swapZvol}" = { # mkswap must come after the zvol exists, otherwise the unit fails the boot
        after = [ "zfs-volume-wait.service" ];
        requires = [ "zfs-volume-wait.service" ];
    };
}
