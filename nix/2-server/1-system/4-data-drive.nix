# Data Drive
# 
# This module manages the mounting of the data drive that stores user files, docker databases and other information. 
# The data drive consists of 2 1TB Hard Drives configured for encrypted ZFS RAID 1. These settings decrypt and mount that 
# storage during boot
#

{
    systemd.tmpfiles.settings."Storage" = {                      # Sets the mount point permissions
        "/Storage" = {
            d = {
                user = "beatlink";
                group = "beatlink";
                mode = "1770";
            };
        };
    };
    fileSystems."/Storage" = {                                                      # Mounts the drive
        device = "data-pool/storage";
        fsType = "zfs";
        options = ["zfsutil" "nofail" ];
        neededForBoot = true;
    };
}