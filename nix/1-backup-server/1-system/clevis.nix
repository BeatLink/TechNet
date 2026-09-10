# Clevis #############################################################################################################################################
#
# Points the shared Clevis module at this host's key material so both LUKS containers unlock from the Tang servers at boot.
#
# One secret covers both: clevis binds a single passphrase per host, so both containers are created with the same zfs_passphrase the ZFS pools used to hold.
#

{ config, ... }:
{
    technet.clevis = {
        enable = true;
        sopsFile = "${config.technet.secrets.path}/clevis.yaml";

        datasets = [ ]; # Nothing on this host is ZFS any more: the root drive and the backup drive are both LUKS

        # cryptroot from disko-btrfs-luks.nix, cryptstorage from data-drive.nix
        luksDevices = [
            "cryptroot"
            "cryptstorage"
        ];

        luksMaxAttempts = 0; # Headless and off site: there is no one at the password prompt the default bound protects, and the ZFS loop never bounded it either
    };
}
