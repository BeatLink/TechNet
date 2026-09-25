# Software ###########################################################################################################################################

{ lib, ... }:
{
    config = lib.mkMerge [

        # State Version ##############################################################################################################################
        {
            system.stateVersion = "24.05";
        }

        # Aarch64 Builds #############################################################################################################################
        # Ragnarok builds aarch64 natively; binfmt stays as the fallback for when it is unreachable.
        {
            nix.distributedBuilds = true;
            nix.buildMachines = [
                {
                    hostName = "ragnarok.technet";
                    sshUser = "beatlink";
                    sshKey = "/persistent/etc/ssh/ssh_host_ed25519_key"; # The nix daemon runs as root, so it cannot reach beatlink's agent
                    systems = [ "aarch64-linux" ];
                    maxJobs = 1; # One derivation at a time, so it gets all three cores nix/1-backup-server/1-system/remote-builder.nix allows
                    speedFactor = 1;
                    supportedFeatures = [ "big-parallel" ];
                }
            ];
            nix.settings.builders-use-substitutes = true; # Ragnarok pulls its own inputs from the caches instead of Odin uploading them over wifi
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
