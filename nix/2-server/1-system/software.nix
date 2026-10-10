# Software Management ################################################################################################################################
#
# The state version, and the emulation that lets this host build the aarch64 hosts' closures.
#
{ lib, ... }:
{
    config = lib.mkMerge [

        # State Version ##############################################################################################################################
        {
            system.stateVersion = "24.11"; # Sets the base version. Don't change unless reinstalling everything
        }

        # Emulation ##################################################################################################################################
        # Vigil's nightly builds compile Thor's and Ragnarok's closures here, since neither builds its own and Ragnarok natively is slower.
        {
            boot.binfmt = {
                emulatedSystems = [ "aarch64-linux" ];
                preferStaticEmulators = true; # The static interpreter is already in the upstream cache; the full qemu closure is a larger pull
            };
        }

        # Build Priority #############################################################################################################################
        # Vigil's builds run inside nix-daemon, so the daemon's own scheduling is what keeps an hours-long emulated build off the services.
        {
            nix.daemonCPUSchedPolicy = "idle";
            nix.daemonIOSchedClass = "idle";
        }
    ];
}
