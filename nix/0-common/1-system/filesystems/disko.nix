# Root Drive Disko ###################################################################################################################################
#
# The declarative layout of the root drive: an EFI partition and a ZFS pool holding root, nix, persistent and home.
#
# Selected by technet.storage.backend = "zfs", the fleet default. The btrfs-luks alternative lives in disko-btrfs-luks.nix.
#

{ config, lib, ... }:
let
    rootPool = "root-pool-${config.networking.hostName}";
in
{
    config = lib.mkIf (config.technet.storage.backend == "zfs") {
        disko.devices = {

            # Disks and partitions -------------------------------------------------------------------------------------------------------------------
            disk.root-drive = {
                type = "disk";
                content = {
                    type = "gpt";
                    partitions = {
                        efi = {
                            size = "512M";
                            type = "EF00";
                            content = {
                                type = "filesystem";
                                format = "vfat";
                                mountpoint = "/boot";
                                mountOptions = [ "umask=0077" ]; # Adds security, prevent world readable boot
                            };
                        };
                        zroot = {
                            size = "100%";
                            content = {
                                type = "zfs";
                                pool = rootPool;
                            };
                        };
                    };
                };
            };

            # Pools ----------------------------------------------------------------------------------------------------------------------------------
            zpool.${rootPool} = {
                type = "zpool";
                options = {
                    autotrim = "on";
                    ashift = "12"; # Never auto: Ragnarok's SSD bridge reported 512-byte sectors at creation and 4096 afterwards, leaving the pool misaligned with no way back short of a rebuild
                };
                rootFsOptions = {
                    mountpoint = "none";
                };
                datasets = {
                    "root" = {
                        type = "zfs_fs";
                        mountpoint = "/";
                        options = {
                            compression = "zstd";
                            # No dedup: nix store paths are unique by hash, so a dedup table costs RAM for nothing it can find, and every pool in the fleet runs without one
                            xattr = "sa";
                            acltype = "posix";
                            "com.sun:auto-snapshot" = "false";
                            encryption = "aes-256-gcm";
                            keyformat = "passphrase";
                            keylocation = "file:///tmp/encryption.key";
                        };
                        postCreateHook = ''
                            zfs set keylocation="prompt" "${rootPool}/root";
                            zpool upgrade -a
                            # Impermanence rolls back to this snapshot every boot; removing it strands the rollback
                            zfs snapshot ${rootPool}/root@blank
                        '';
                    };
                    "root/nix" = {
                        type = "zfs_fs";
                        mountpoint = "/nix";
                        options = {
                            atime = "off";
                        };
                    };
                    "root/persistent" = {
                        type = "zfs_fs";
                        mountpoint = "/persistent";
                        options = {
                            "com.sun:auto-snapshot" = "true";
                        };
                    };
                    "root/home" = {
                        type = "zfs_fs";
                        mountpoint = "/home";
                        options = {
                            "com.sun:auto-snapshot" = "true";
                        };
                        postCreateHook = ''
                            # Impermanence rolls back to this snapshot every boot; removing it strands the rollback
                            zfs snapshot ${rootPool}/root/home@blank
                        '';
                    };
                };
            };
        };
    };
}
