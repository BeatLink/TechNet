# Borg Repositories ##################################################################################################################################
#
# The receiving end of the network's backups: one repository per source host, each authorised only for that host's own borg key.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Backup Tree Ownership ######################################################################################################################
        {
            systemd.tmpfiles.settings."Backup-Drive"."/Storage/Backups" = {
                d = {
                    user = "borg";
                    group = "borg";
                    mode = "0750";
                };
                Z = {
                    user = "borg";
                    group = "borg";
                    mode = "0750";
                };
            };
        }

        # Repositories ###############################################################################################################################
        {
            services.borgbackup.repos = {
                odin = {
                    authorizedKeys = [
                        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhnn5URZ/2Dx4yFz4E2vfKhQGViGSDRgSixehg+wUXj odin-borg-repo-borgmatic"
                    ];
                    path = "/Storage/Backups/Odin";
                };
                heimdall = {
                    authorizedKeys = [
                        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFdCCw57/UyY1YBTjif2/bMsVDSOVurJ946fKMsBOyoI heimdall-borg-key"
                    ];
                    path = "/Storage/Backups/Heimdall";
                };
            };
        }

    ];
}
