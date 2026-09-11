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
                laptop-vorta = {
                    authorizedKeys = [
                        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFERN9fyw16t2LvfrrZdO1CpY5ZWEolg2bY1ZF4WF2SU odin-borg-key"
                    ];
                    path = "/Storage/Backups/Laptop/Vorta";
                };
                laptop-borgmatic = {
                    authorizedKeys = [
                        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhnn5URZ/2Dx4yFz4E2vfKhQGViGSDRgSixehg+wUXj odin-borg-repo-borgmatic"
                    ];
                    path = "/Storage/Backups/Laptop/Borgmatic";
                };
                server = {
                    authorizedKeys = [
                        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFdCCw57/UyY1YBTjif2/bMsVDSOVurJ946fKMsBOyoI heimdall-borg-key"
                    ];
                    path = "/Storage/Backups/Server/Borgmatic";
                };
            };
        }
    ];
}
