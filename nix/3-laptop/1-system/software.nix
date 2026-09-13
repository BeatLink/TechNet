# Software ###########################################################################################################################################

{ lib, ... }:
{
    config = lib.mkMerge [

        # State Version ##############################################################################################################################
        {
            system.stateVersion = "24.05";
        }

        # Aarch64 Builds #############################################################################################################################
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
