# Remote Builder #####################################################################################################################################
#
# Dormant: Odin builds aarch64 locally under binfmt rather than offloading to a 2GB board. The authorisation is kept so turning it back on is a
# one-file change on Odin. What is authorised is Odin's SSH host key, because its nix-daemon runs as root and connects as beatlink with that key.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Builder Authorisation ######################################################################################################################
        {
            users.users.beatlink.openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINnDCoaEbXWh0rJshd2alkRQrGo+jsmKssXXMVbivl4p Odin"
            ];
        }

        # Build Resource Limits ######################################################################################################################
        # The ARC cap protects any burst of allocation on a 2GB board, not just builds, and zram in 0-common backstops what still spills.
        {
            boot.extraModprobeConfig = "options zfs zfs_arc_max=536870912"; # A module parameter, not a runtime tunable, since zfs loads in the initrd
            nix.settings.cores = 3;
        }
    ];
}
