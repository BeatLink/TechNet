# Root Drive Disko (btrfs on LUKS) ###################################################################################################################
#
# The same roles as the ZFS layout -- an EFI partition, then root, nix, persistent and home -- as btrfs subvolumes inside one LUKS container.
#
# Selected by technet.storage.backend = "btrfs-luks". LUKS2 defaults to aes-xts-plain64, which dm-crypt runs through the kernel crypto API and so
# through the CPU's aes/pmull instructions; that is the entire reason this layout exists. See storage-backend.nix for the measurements.
#

{ config, lib, ... }:
{
    config = lib.mkIf (config.technet.storage.backend == "btrfs-luks") {
        disko.devices.disk.root-drive = {
            type = "disk";
            content = {
                type = "gpt";
                partitions = {

                    # EFI ----------------------------------------------------------------------------------------------------------------------------
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

                    # Encrypted Root -----------------------------------------------------------------------------------------------------------------
                    cryptroot = {
                        size = "100%";
                        content = {
                            type = "luks";
                            name = "cryptroot"; # Names /dev/mapper/cryptroot, which the rollback service and technet.clevis.luksDevices both spell out
                            passwordFile = "/tmp/encryption.key"; # Written by the installer; disko feeds it through $(cat), which strips the trailing newline the same way rebind-clevis does
                            settings = {
                                allowDiscards = true; # Lets fstrim reach the eMMC through dm-crypt, at the cost of revealing which blocks are unused
                            };

                            content = {
                                type = "btrfs";
                                extraArgs = [ "-f" ];

                                subvolumes = {
                                    "@root" = {
                                        mountpoint = "/";
                                        mountOptions = [
                                            "compress=zstd"
                                            "noatime"
                                            "discard=async"
                                        ];
                                    };
                                    "@nix" = {
                                        mountpoint = "/nix";
                                        mountOptions = [
                                            "compress=zstd"
                                            "noatime"
                                            "discard=async"
                                        ];
                                    };
                                    "@persistent" = {
                                        mountpoint = "/persistent";
                                        mountOptions = [
                                            "compress=zstd"
                                            "noatime"
                                            "discard=async"
                                        ];
                                    };
                                    "@home" = {
                                        mountpoint = "/home";
                                        mountOptions = [
                                            "compress=zstd"
                                            "noatime"
                                            "discard=async"
                                        ];
                                    };
                                };

                                # Impermanence snapshots @root and @home back from these every boot; removing them strands the rollback
                                postCreateHook = ''
                                    MNTPOINT=$(mktemp -d)
                                    mount /dev/mapper/cryptroot "$MNTPOINT" -o subvol=/
                                    trap 'umount "$MNTPOINT"; rm -rf "$MNTPOINT"' EXIT
                                    btrfs subvolume snapshot -r "$MNTPOINT/@root" "$MNTPOINT/@root-blank"
                                    btrfs subvolume snapshot -r "$MNTPOINT/@home" "$MNTPOINT/@home-blank"
                                '';
                            };
                        };
                    };
                };
            };
        };
    };
}
