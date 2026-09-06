# Borg Repositories ##################################################################################################################################
#
# The receiving end of the network's backups: one repository per source host, each authorised only for that host's own borg key.
# Vigil-triggered backups reuse the source host's key rather than one of Vigil's, so Vigil never holds write credentials to a repository.
#

{ lib, ... }:
{
    config = lib.mkMerge [

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

        # Resource Limits ############################################################################################################################
        # borg serve arrives as an SSH forced command rather than a unit, so the ceilings go on the borg user's slice, where concurrent sessions share one budget.
        {
            users.users.borg.uid = 999; # Names the slice below; the upstream module leaves the uid to dynamic allocation

            systemd.slices."user-999".sliceConfig = {
                MemoryHigh = "384M"; # Reclaims rather than kills, so a prune or check that needs the headroom still finishes
                MemoryMax = "1G";
                CPUQuota = "250%";
                CPUWeight = 70;
                TasksMax = 64;
            };
        }
    ];
}
