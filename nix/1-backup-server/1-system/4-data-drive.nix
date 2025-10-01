# Data Drive
#
# Configures settings for mounting the Data Drive for backups
#

{ config, ... }:
{
    systemd.tmpfiles.settings."Backup-Drive" = {
        # Sets the mount point permissions
        "/Storage" = {
            Z = {
                user = "borg";
                group = "borg";
                mode = "0770";
            };
        };
    };
    fileSystems."/Storage" = {
        # Mounts the drive
        device = "data-pool-${config.networking.hostName}/storage";
        fsType = "zfs";
        options = [
            "zfsutil"
            "nofail"
        ];
        neededForBoot = true;
    };
}
