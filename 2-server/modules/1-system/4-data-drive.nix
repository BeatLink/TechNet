# Data Drive #########################################################################################################################
# 
# This module manages the mounting of the data drive that stores user files, docker databases and other information. 
# The data drive consists of 2 1TB Hard Drives configured for RAID 1 with a LUKS overlay on top. These settings decrypt and mount that 
# storage during boot
#
#######################################################################################################################################
{

    # Data Drive Mounting
    boot = {
        swraid = {                                                      # Enables RAID for the data storage drive
            enable = true;
            mdadmConf = ''
                ARRAY /dev/md/0  metadata=1.2 UUID=218b060a:70baa2ea:ca8ece09:96675c63 name=Heimdall:0
                PROGRAM /bin/wall
            '';
        };    
    };

    boot.initrd.luks.devices.Storage.device = "/dev/md/0";              # Decrypts the data storage drive

    systemd.tmpfiles.rules = [ 
        "d /Storage 1770 beatlink beatlink"                             # Creates the mount point and sets needed permissions
    ];

    fileSystems."/Storage" = {                                          # Mounts the decrypted volume
        device = "/dev/mapper/Storage";
        fsType = "ext4";
        options = ["defaults" "nofail" "discard"];
    };

}