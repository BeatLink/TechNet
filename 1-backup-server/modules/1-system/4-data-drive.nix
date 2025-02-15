# Data Drive ############################################################################################################################
#
# Configures settings for mounting the Data Drive for backups
#
###########################################################################################################################################

{
    systemd.tmpfiles.settings."Backup-Drive" = {                      # Sets the mount point permissions
        "/Storage" = {
            Z = {
                user = "borg";
                group = "borg";
                mode = "0770";
            };
        };
    };
    fileSystems."/Storage" = {                                                      # Mounts the drive
        device = "/dev/disk/by-uuid/4c6831d6-0d99-4d5a-805f-88d7878d6c4b";
        fsType = "ext4";
        options = ["defaults" "nofail" "discard"];
    };
}