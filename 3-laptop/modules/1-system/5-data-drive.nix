# The majority of state including application settings, files and databases are stored on a 1TB NVMe SSD encrypted with LUKS
# These settings decrypt that drive during boot

    # Data Drive Mounting
    /*boot = {
        swraid = {                                                      # Enables RAID for the data storage drive
            enable = true;
            mdadmConf = ''
                ARRAY /dev/md/0  metadata=1.2 UUID=218b060a:70baa2ea:ca8ece09:96675c63 name=Heimdall:0
                PROGRAM /bin/wall
            '';
        };    
    };
    boot.initrd.luks.devices.Storage.device = "/dev/md/0";               # Decrypts the data storage drive
    systemd.tmpfiles.rules = [ 
        "d /Storage 1770 beatlink beatlink"                             # Creates the mount point and sets needed permissions
    ];
    fileSystems."/Storage" = {
        device = "/dev/mapper/Storage";
        fsType = "ext4";
        options = ["defaults" "nofail" "discard"];
    };*/
