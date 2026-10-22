# Clevis #############################################################################################################################################
#
# Points the shared Clevis module at this host's key material so both LUKS containers unlock from the Tang servers at boot.
#
# One passphrase covers both: Odin's rebind-clevis binds each container from ragnarok_encryption_key in secrets/admin, and it also opens
# either one at the console, where typing it once unlocks both because systemd-cryptsetup caches it in the kernel keyring.
#

{ ... }:
{
    technet.clevis = {
        enable = true;

        datasets = [ ]; # Nothing on this host is ZFS any more: the root drive and the backup drive are both LUKS

        # cryptroot from disko-btrfs-luks.nix, cryptstorage from data-drive.nix
        luksDevices = [
            "cryptroot"
            "cryptstorage"
        ];
    };
}
