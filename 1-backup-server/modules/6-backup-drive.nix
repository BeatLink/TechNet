# Backup Drive ############################################################################################################################
#
# Configures settings for mounting the Backup Drive
#
###########################################################################################################################################

{ config, lib, pkgs, ... }: 
{
    systemd.tmpfiles.rules = [                                                      # Sets the mount point permissions
        "d /Storage 1770 borg borg"
    ];
    fileSystems."/Storage" = {                                                      # Mounts the drive
        device = "/dev/disk/by-uuid/4c6831d6-0d99-4d5a-805f-88d7878d6c4b";
        fsType = "ext4";
        options = ["defaults" "nofail" "discard"];
    };
}