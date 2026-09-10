# Clevis #############################################################################################################################################
#
# Points the shared Clevis module at this host's key material so the root container and the backup pool unlock from the Tang servers at boot.
#
# One secret covers both: clevis binds a single passphrase per host, so the LUKS container is installed with the same zfs_passphrase the pool already holds.
#

{ config, ... }:
{
    technet.clevis = {
        enable = true;
        sopsFile = "${config.technet.secrets.path}/clevis.yaml";

        datasets = [ "data-pool-${config.networking.hostName}/storage" ]; # Only the backup drive is ZFS; the root drive is the LUKS device below

        luksDevices = [ "cryptroot" ]; # Named by disko-btrfs-luks.nix

        luksMaxAttempts = 0; # Headless and off site: there is no one at the password prompt the default bound protects, and the ZFS loop never bounded it either
    };
}
