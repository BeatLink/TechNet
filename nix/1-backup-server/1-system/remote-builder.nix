# Remote Builder #####################################################################################################################################
#
# Allows hosts to use this device to build aarch64 binaries, which is what Odin's nix.buildMachines points at.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Builder Authorisation ######################################################################################################################
        {
            users.users.beatlink.openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINnDCoaEbXWh0rJshd2alkRQrGo+jsmKssXXMVbivl4p Odin" # Odin's host key, because its nix daemon connects as root
            ];
        }

        # Build Resource Limits ######################################################################################################################
        # One job at a time on three of the four cores, because 2G of RAM is the real limit here; the 16G swap it spills into is on the USB 3 SSD.
        {
            nix.settings.cores = 3;
            nix.settings.max-jobs = 1;
        }
    ];
}
