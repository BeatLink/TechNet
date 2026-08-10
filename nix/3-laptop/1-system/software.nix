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
    ];
}
