

# Disko Data Drive #########################################################################################################################
#
# This section declaratively describes the filesystem structure for the data drive. It is used by disko during installation to format and partition the 
# installation drive. It is also used during boot to find and mount the needed partitions
#
# The disk partition structure follows the "Erase your Darlings" philosophy whereby the root filesystem is erased at every boot and rebuilt
# from the contents of the Nix store and this configuration flake 
#
# Disk partition generated Dwith help from https://ethan.roo.ke/notes/nix-on-kimsufi/
# 
###########################################################################################################################################

{
    disko.devices = {
        disk = {
            main = {
                type = "disk";
                device = "/dev/disk/by-id/nvme-Corsair_MP600_MICRO_A828B42710C0GL";
                content = {
                    type = "gpt";                                       # GPT Partition tables used on modern systems
                    partitions = {
                        zfs-data-partition = {                          # This creates a ZFS partition to be added to the ZFS pool
                            size = "100%";
                            content = {
                                type = "zfs";
                                pool = "zfs-data-pool";
                            };
                        };
                    };
                };
            };
        };
        zpool = {                                                       # Creates a ZFS pool for managing storage volumes
            zfs-data-pool = {
                type = "zpool";
                options = {
                    autotrim = "on";
                };
                rootFsOptions = {
                    mountpoint = "none";                                # We will be mounting the children datasets, not this root one
                    compression = "zstd";                               # Compresses files to save space
                    xattr = "sa";                                       # Allows extended attributes stored in the filesystem inodes
                    acltype = "posix";                                  # Uses posix compliant ACL for extended attributes
                    "com.sun:auto-snapshot" = "false";                  # Prevents autosnapshots in general (will be enabled for specific datasets later)
                    encryption = "aes-256-gcm";
                    keyformat = "passphrase";
                    keylocation = "file:///tmp/disk-1.key";

                };  
                postCreateHook = ''
                    zfs set keylocation="prompt" "zfspool";             # use this to read the key during boot
                '';                                                      
                datasets = {
                    storage = {                                           # The dataset for the root filesystem mounted at /
                        type = "zfs_fs";
                        mountpoint = "/Storage";
                        options = {
                            mountpoint = "legacy";
                            "com.sun:auto-snapshot" = "true";           # Generates snapshots to persist data
                        };
                    };
                };
            };
        };
    };
    fileSystems = {
        "/Storage".neededForBoot = true;
    };
}



# The majority of state including application settings, files and databases are stored on a 1TB NVMe SSD encrypted with LUKS
# These settings decrypt that drive during boot

    # Data Drive Mounting
    /*boot = {

    };
    systemd.tmpfiles.rules = [ 
        "d /Storage 1770 beatlink beatlink"                             # Creates the mount point and sets needed permissions
    ];
    fileSystems."/Storage" = {
        device = "/dev/mapper/Storage";
        fsType = "ext4";
        options = ["defaults" "nofail" "discard"];
    };*/

