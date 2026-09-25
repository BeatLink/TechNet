# Software ###########################################################################################################################################

{ lib, ... }:
{
    config = lib.mkMerge [

        # State Version ##############################################################################################################################
        {
            system.stateVersion = "24.05";
        }

        # Aarch64 Builds #############################################################################################################################
        # Emulated here rather than sent to Ragnarok, which measured 1053s against Odin's 691s for the same package -- three A53 cores and 2GB of RAM
        # lose to twelve Zen 3 threads even at a 10-20x emulation penalty.
        {
            nix.distributedBuilds = false;
            boot.binfmt = {
                emulatedSystems = [ "aarch64-linux" ];
                preferStaticEmulators = true; # A static interpreter stays reachable from a chroot, so nixos-install --root can run aarch64 builders
            };
        }

        # Binary Cache ###############################################################################################################################
        # Odin builds every host's closure, so it is the machine whose output the rest of the fleet most wants to substitute.
        {
            technet.atticPush.enable = true;
        }
    ];
}
