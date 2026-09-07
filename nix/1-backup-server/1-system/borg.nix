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

            # This host exists to receive backups, so borg gets priority rather than a ceiling. CPUWeight is what expresses that: it wins against
            # syncthing's 30 whenever both want the disk and costs nothing when they do not. The CPUQuota that was here never once throttled --
            # nr_throttled stayed at 0 -- so it bounded nothing while risking a slow restore.
            #
            # MemoryMax is gone too. It was added when orphaned borg sessions reached 490M, but that was a leak with two causes, both since fixed:
            # sshd never reaped sessions whose client had gone, and Vigil's monitor timeouts were unenforceable against sudo. A hard cap would only
            # have turned that leak into an OOM kill mid-write, which is how a repo ends up needing break-lock. MemoryHigh reclaims instead.
            systemd.slices."user-999".sliceConfig = {
                MemoryHigh = "384M";
                CPUWeight = 70;
                TasksMax = 64;
            };
        }
    ];
}
