# Root Drive Disko ###################################################################################################################################
#
# The declarative layout of the root drive: an EFI partition and a ZFS pool holding root, nix, persistent and home.
#

{ config, ... }:
let
    rootPool = "root-pool-${config.networking.hostName}";
in
{
    disko.devices = {

        # Disks and partitions -----------------------------------------------------------------------------------------------------------------------
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

        # Pools --------------------------------------------------------------------------------------------------------------------------------------
        zpool.${rootPool} = {
            type = "zpool";
            options = {
                autotrim = "on";
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
                        dedup = "on";
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
}
