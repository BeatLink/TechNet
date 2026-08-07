# Filesystem #########################################################################################################################################

{ config, ... }:
let
    rootPool = "root-pool-${config.networking.hostName}";
    dataPool = "data-pool-${config.networking.hostName}";
    swapZvol = "dev-zvol-${rootPool}-swap";
in
{
    # ZFS Support ####################################################################################################################################
    boot = {
        supportedFilesystems = [ "zfs" ];
        initrd = {
            supportedFilesystems = [ "zfs" ];
            # Data pool must import after root, otherwise the two race
            systemd.services."zfs-import-${dataPool}".after = [ "zfs-import-${rootPool}.service" ];
        };
        zfs.forceImportRoot = false;
    };

    # Root Drive Disko ###############################################################################################################################
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
                "root/swap" = {
                    type = "zfs_volume";
                    size = "16G";
                    content = {
                        type = "swap";
                        randomEncryption = true;
                        discardPolicy = "both";
                    };
                };
            };
        };

    };

    # Mounts #########################################################################################################################################
    fileSystems = {
        "/".neededForBoot = true;
        "/boot".neededForBoot = true;
        "/nix".neededForBoot = true;
        "/persistent".neededForBoot = true;
        "/home".neededForBoot = true;
        # Created by hand at install, not by disko. nofail keeps a missing pool from stranding the boot
        "/Storage" = {
            device = "${dataPool}/storage";
            fsType = "zfs";
            options = [
                "zfsutil"
                "nofail"
            ];
            neededForBoot = true;
        };
    };

    # Swap ###########################################################################################################################################
    # mkswap must come after the zvol exists. Otherwise, the unit fails the boot
    systemd.services."mkswap-${swapZvol}" = {
        after = [ "zfs-volume-wait.service" ];
        requires = [ "zfs-volume-wait.service" ];
    };

    # Filesystem Maintenance #########################################################################################################################
    services = {
        fstrim.enable = true;
        zfs = {
            trim.enable = true;
            autoScrub.enable = true;
        };
    };
}
