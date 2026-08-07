# Root Drive ##########################

{ config, lib, ... }:
let
    zvolSwaps = lib.filter (swap: lib.hasPrefix "/dev/zvol/" swap.device) config.swapDevices;

    # mkswap runs before the zvol exists otherwise, and the unit fails the boot
    waitForZvol =
        swap:
        lib.nameValuePair "mkswap-${swap.deviceName}" {
            after = [ "zfs-volume-wait.service" ];
            requires = [ "zfs-volume-wait.service" ];
        };
in
{
    # Creates Disks at installation, guides mounting during boot
    disko.devices = {
        # Disks and Partitions
        disk.root-drive = {
            type = "disk";
            content = {
                type = "gpt";
                partitions = {
                    # Bootloader
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
                    # Root Pool
                    zroot = {
                        size = "100%";
                        content = {
                            type = "zfs";
                            pool = "root-pool-${config.networking.hostName}";
                        };
                    };
                };
            };
        };
        # Pools
        zpool."root-pool-${config.networking.hostName}" = {
            type = "zpool";
            options = {
                autotrim = "on";
            };
            rootFsOptions = {
                mountpoint = "none"; # Data stored in children datasets
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
                        # Prompt for Decryption Key at Boot
                        zfs set keylocation="prompt" "root-pool-${config.networking.hostName}/root";

                        # Enable all features
                        zpool upgrade -a

                        # Snapshot for Impermanence. Future boots roll back to this
                        zfs snapshot root-pool-${config.networking.hostName}/root@blank
                    '';
                };
                "root/nix" = {
                    type = "zfs_fs";
                    mountpoint = "/nix";
                    options = {
                        atime = "off"; # Nix does not use atime (impure), might as well turn it of
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
                        # Snapshot for Impermanence. Future boots roll back to this
                        zfs snapshot root-pool-${config.networking.hostName}/root/home@blank
                    '';
                };
                "root/swap" = {
                    type = "zfs_volume";
                    size = "16G";
                    content = {
                        type = "swap";
                        randomEncryption = true;
                        discardPolicy = "both"; # Enables TRIM for the ZVOL
                    };
                };
            };
        };

    };

    fileSystems = {
        "/".neededForBoot = true;
        "/boot".neededForBoot = true;
        "/nix".neededForBoot = true;
        "/persistent".neededForBoot = true;
        "/home".neededForBoot = true;
    };

    systemd.services = lib.listToAttrs (map waitForZvol zvolSwaps);
}
