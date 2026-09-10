# Storage Backend ####################################################################################################################################
#
# Which of the two root-drive implementations a host uses, and whether /Storage is the fleet's ZFS data pool. The layout, the boot-time wipe and the
# unlock all have to agree with each other, so they read one option rather than being switched independently and drifting apart.
#

{ lib, ... }:
{
    options.technet.storage.backend = lib.mkOption {
        type = lib.types.enum [
            "zfs"
            "btrfs-luks"
        ];
        default = "zfs";
        description = ''
            Root drive implementation for this host.

            `zfs` is the fleet default: one pool per host with ZFS native
            aes-256-gcm, rolled back to a blank snapshot each boot and unlocked
            by clevis loading the dataset key.

            `btrfs-luks` puts btrfs subvolumes inside a LUKS container instead.
            It exists because OpenZFS carries its own crypto and never calls the
            kernel crypto API, so on aarch64 its AES-GCM runs as generic C while
            the CPU's own aes/pmull instructions sit unused. dm-crypt is GPL
            kernel code and does reach them. Measured on Thor, MB/s write/read:
            ZFS gcm 21.8/23.8, ZFS ccm 29.6/34.2, LUKS aes-xts + btrfs 91.4/195.9.

            Only worth setting on a host whose CPU lacks accelerated ZFS crypto;
            x86 hosts have AES-NI and PCLMULQDQ and are faster on ZFS as they are.
        '';
    };

    options.technet.storage.zfsDataPool = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
            Whether /Storage on this host is the fleet's `data-pool-<host>/storage`
            ZFS dataset, mounted by mounts.nix.

            Independent of `backend`, because the two drives are independent: a
            host can move its root off ZFS and keep the pool, or the reverse.
            False on a host that describes its own data drive instead, which is
            Thor with its card and Ragnarok with its backup disk -- both LUKS
            containers holding btrfs.
        '';
    };
}
