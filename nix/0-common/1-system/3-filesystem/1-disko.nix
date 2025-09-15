# Disko #########################################################################################################################################
#
# Disko is used to declaratively describe the filesystem structure. It is used by nixos-anywhere during installation to format and partition the root
# drive. It is also used to mount the filesystems at boot.
#

{
    disko.devices = {
        disk.root-drive = {
            type = "disk";
            content = {
                type = "gpt"; # GPT Partition tables used on modern systems
                partitions = {
                    efi = {
                        # The EFI System Partition (ESP) stores bootloader information used on UEFI systems
                        size = "512M";
                        type = "EF00";
                        content = {
                            type = "filesystem";
                            format = "vfat";
                            mountpoint = "/boot";
                        };
                    };
                    zroot = {
                        # This creates a partition to be added to the ZFS pool
                        size = "100%";
                        content = {
                            type = "zfs";
                            pool = "root-pool";
                        };
                    };
                };
            };
        };
        zpool.root-pool = {
            # Creates a pool for managing zfs datasets
            type = "zpool";
            options = {
                autotrim = "on";
            };
            rootFsOptions = {
                mountpoint = "none"; # We will be mounting the children datasets, not this root one
                compression = "zstd"; # Compresses files to save space
                xattr = "sa"; # Allows extended attributes stored in the filesystem inodes
                acltype = "posix"; # Uses posix compliant ACL for extended attributes
                "com.sun:auto-snapshot" = "false"; # Prevents autosnapshots in general (will be enabled for specific datasets later)
                encryption = "aes-256-gcm";
                keyformat = "passphrase";
                keylocation = "file:///tmp/encryption.key";

            };
            postCreateHook = ''
                zfs set keylocation="prompt" "root-pool";             # use this to read the key during boot
            '';
            datasets = {
                root = {
                    # The dataset for the root filesystem mounted at /
                    type = "zfs_fs";
                    mountpoint = "/";
                    options.mountpoint = "legacy"; # This manages the mountpoint manually using typical tools (mount, fstab, etc)
                    postCreateHook = ''
                        zfs snapshot root-pool/root@blank             # This takes a snapshot of the blank pool. Every boot, the system will rollback to this snapshot
                    '';
                };
                nix = {
                    # The dataset for the nix store mounted at /nix
                    type = "zfs_fs";
                    mountpoint = "/nix";
                    options = {
                        mountpoint = "legacy";
                        atime = "off"; # Nix does not use atime (impure), might as well turn it off
                    };
                };
                persistent = {
                    # The dataset for persistent system files that are preserved between rollbacks (ssh host keys, docker volumes, etc), mounted at /persistent
                    type = "zfs_fs";
                    mountpoint = "/persistent";
                    options = {
                        mountpoint = "legacy";
                        "com.sun:auto-snapshot" = "true"; # Generates snapshots to persist data
                    };
                };
                home = {
                    # The dataset for the user profiles mounted at /home
                    type = "zfs_fs";
                    mountpoint = "/home";
                    options = {
                        mountpoint = "legacy";
                        "com.sun:auto-snapshot" = "true"; # Generates snapshots to persist data
                    };
                    postCreateHook = ''
                        zfs snapshot root-pool/home@blank             # This takes a snapshot of the blank pool. Every boot, the system will rollback to this snapshot
                    '';
                };
            };
        };
    };

}
