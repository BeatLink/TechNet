# Mounts #############################################################################################################################################
#
# The mounts needed before the impermanence rollback runs, plus /Storage from the data pool.
#

{ config, ... }:
let
    dataPool = "data-pool-${config.networking.hostName}";
in
{
    fileSystems = {
        "/".neededForBoot = true;
        "/boot".neededForBoot = true;
        "/nix".neededForBoot = true;
        "/persistent".neededForBoot = true;
        "/home".neededForBoot = true;
        "/Storage" = {
            device = "${dataPool}/storage"; # Created by hand at install, not by disko
            fsType = "zfs";
            options = [
                "zfsutil"
                "nofail" # nofail keeps a missing pool from stranding the boot
            ];
            neededForBoot = true; # Must stay true: clevis unlocks the dataset only in the initrd, so a stage 2 mount finds no key and fails to decrypt
        };
    };
}
