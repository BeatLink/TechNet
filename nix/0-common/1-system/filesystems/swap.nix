# Swap ###############################################################################################################################################
#
# Zram compressed swap, and boot ordering for the swap zvol declared in disko.nix.
#

{ config, lib, ... }:
let
    swapZvol = "dev-zvol-root-pool-${config.networking.hostName}-swap";
in
{
    config = lib.mkMerge [

        # Zram Swap ##################################################################################################################################
        {
            zramSwap.enable = true;
        }

        # Swap Zvol ##################################################################################################################################
        {
            systemd.services."mkswap-${swapZvol}" = { # mkswap must come after the zvol exists, otherwise the unit fails the boot
                after = [ "zfs-volume-wait.service" ];
                requires = [ "zfs-volume-wait.service" ];
            };
        }
    ];
}
