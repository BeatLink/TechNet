# Remote Builder #####################################################################################################################################
#
# Allows hosts to use this device to build aarch64 binaries
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
        {
            nix.settings.cores = 3;
        }
    ];
}
