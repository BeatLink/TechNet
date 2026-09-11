# Clevis #############################################################################################################################################
#
# Points the shared Clevis module at this host's key material so both LUKS containers unlock from the Tang servers at boot.
#
# One secret covers both: rebind-clevis binds each container from the same zfs_passphrase the ZFS pools used to hold, and that passphrase also opens
# either one at the console, where typing it once unlocks both because systemd-cryptsetup caches it in the kernel keyring.
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
    };
}
