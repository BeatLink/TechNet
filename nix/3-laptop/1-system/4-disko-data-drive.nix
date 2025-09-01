

# Disko Data Drive
#
# This section declaratively describes the filesystem structure for the data drive. It is optionally used by disko during installation to format and 
# partition the data drive. It is also used during boot to find and mount the needed partitions
#

{
    disko.devices = {
        disk.data-drive = {
            type = "disk";
            device = "/dev/disk/by-id/nvme-Corsair_MP600_MICRO_A828B42710C0GL";
            content = {
                type = "gpt";                                       # GPT Partition tables used on modern systems
                partitions = {
                    zfs-data-partition = {                          # This creates a ZFS partition to be added to the ZFS pool
                        size = "100%";
                        content = {
                            type = "zfs";
                            pool = "data-pool";
                        };
                    };
                };
            };
        };
        zpool.data-pool = {
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
                zfs set keylocation="prompt" "data-pool";             # use this to read the key during boot
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
    fileSystems = {
        "/Storage".neededForBoot = true;
    };
    systemd.tmpfiles.rules = [ 
        "d /Storage 1770 beatlink beatlink"                             # Creates the mount point and sets needed permissions
    ];
}





